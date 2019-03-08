Shader "Custom/RefractShader"
{
    Properties
    {
        _NoiseTex ("Noise", 2D) = "white" {}
        _CutoffThresh ("Cut off", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        GrabPass { "_GrabTex" }
        
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
            
            sampler2D _GrabTex;
            sampler2D _NoiseTex;
            float _CutoffThresh;

            v2f vert (appdata v)
            {
                v.vertex.xyz = v.normal.xyz * _CutoffThresh * 0.99;
                
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float refractionAmount = (1 - _CutoffThresh) / 2;
                i.grabPos.x += tex2D(_NoiseTex, i.uv) * refractionAmount;
                i.uv.x += 0.1;
                i.grabPos.y += tex2D(_NoiseTex, i.uv) * refractionAmount;
                i.uv.y += 0.1;
                i.grabPos.z += tex2D(_NoiseTex, i.uv) * refractionAmount;
                
                return tex2Dproj(_GrabTex, i.grabPos);
            }
            ENDCG
        }
        
    }
}
