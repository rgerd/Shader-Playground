Shader "Custom/DissolveShader"
{
    Properties
    {
        _NoiseTex ("Noise", 2D) = "white" {}
        _CutoffThresh ("Cut off", Range(0, 1)) = 0
        _LineThickness ("Line thickness", Range(0, 0.5)) = 0
        _MainColor ("Main color", Color) = (1, 1, 1, 1)
        _LineColor ("Line color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
            };

            sampler2D _NoiseTex;
            float _CutoffThresh;
            float _LineThickness;
            fixed4 _MainColor;
            fixed4 _LineColor;

            v2f vert (appdata v)
            {
                v.vertex.xyz = v.normal.xyz * _CutoffThresh;
                
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float noise = tex2D(_NoiseTex, i.uv).r;
                
                clip(noise - _CutoffThresh);
                
                return ((noise - _CutoffThresh) < _LineThickness) && (_CutoffThresh > 0) ? _LineColor : _MainColor;
            }
            ENDCG
        }
        
    }
}
