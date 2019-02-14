Shader "PortalShader"
{
    Properties
    {
        _DispTex("Displacement Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        
        GrabPass
        {
            "_BehindTexture"
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 grabPos : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
            
            v2f vert(appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }
            
            sampler2D _BehindTexture;
            sampler2D _DispTex;
            
            fixed4 frag(v2f i) : SV_Target
            {
                float4 disp = tex2Dproj(_DispTex, i.grabPos + _SinTime);
                fixed4 bgColor = tex2Dproj(_BehindTexture, i.grabPos + disp);
                return bgColor;
            }
            
            ENDCG
        }
    }
}
