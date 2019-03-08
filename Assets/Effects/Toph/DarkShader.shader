Shader "Custom/DarkShader"
{
    Properties
    {
        _WaveData ("Wave data", 2D) = "black" {}
        _MaxWaveIndex ("Maximum wave index to update", Int) = 0
        _WaveTexSideLen ("Wave texture side length", Int) = 1
        
        _MaxSceneDist ("Maximum value in origin vector", Float) = 50000
        _MaxWaveDist ("Maximum distance wave can travel", Float) = 100
        
        _BandSize ("Band thickness", Float) = 0.1
        _BandFade ("Band fade", Range(0, 1)) = 0.696
        _NumCircles ("Number of circles", Int) = 16
        _CircleSpacing ("Circle spacing", Float) = 0.3
        [MaterialToggle] _UseManhattan ("Use Manhattan Distance", Float) = 0
        _GlowBrightness ("Glow Brightness", Float) = 1
        _GlowRadius ("Glow Radius", Float) = 8
        _GlowSustain ("Glow Sustain", Float) = 15
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            sampler2D _WaveData;
            int _MaxWaveIndex;
            int _WaveTexSideLen;
            
            float _MaxSceneDist;
            float _MaxWaveDist;
            
            float _BandSize;
            float _BandFade;
            int _NumCircles;
            float _CircleSpacing;
            float _UseManhattan;
            float _GlowBrightness;
            float _GlowRadius;
            float _GlowSustain;
            
            struct VertIn
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertOut
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 ws_vertex : COLOR;
            };

            VertOut vert (VertIn v)
            {
                VertOut o;
                o.ws_vertex = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float peak(float value, float target, float thickness, float fade)
            {
                float d = sqrt((value - target) * (value - target));
                return d < thickness ? 1 - (fade - ((thickness - d) / thickness)) : 0;
            }

            float manhattanLength(float3 vec)
            {
                return abs(vec.x) + abs(vec.y) + abs(vec.z);
            }

            // Good sustain: 15
            float logGlow(float x, float sustain) {
              float sustainedX = sustain - min(x, sustain - 0.00001);
              return max(log(sustainedX / 16) + 3, 0);
            }

            // Good sustain: 8
            float inverseGlow(float x, float sustain) {
              if (x < sustain) return 1;
              return (1.0 / ((x - sustain) + 10)) * 10;
            }

            // Good sustain: 35
            float linearGlow(float x, float sustain) {
              return max((sustain - x) / sustain, 0);
            }
            
            float intensity(float3 waveOrigin, float waveDist, float3 fragPos) {
                float targetDist = waveDist;
                float intensity = 0;
                float3 distVector = fragPos - waveOrigin;
                float dist = _UseManhattan == 1 ? manhattanLength(distVector) : length(distVector);
                
                for (int c = 0; c < _NumCircles; c++) {
                    float circleDist = dist + _CircleSpacing * c * ((float) c / 50.0);
                    if (c != 0) {
                      intensity += lerp(peak(
                          circleDist,
                          targetDist,
                          _BandSize / (c + 1),
                          _BandFade
                       ), 0, ((float)c + 1) / (float) _NumCircles);
                    } else {
                      float glowIntensity = max(_GlowRadius - dist, 0) * (_GlowBrightness / 1000.0);
                      glowIntensity *= inverseGlow(targetDist, _GlowSustain);
                      intensity = circleDist < targetDist ? glowIntensity : 0;
                    }
                }
                
                return intensity;
            }
            
            float2 waveIndexToUV(int ind) {
                int coordX = ind % _WaveTexSideLen;
                int coordY = ind / _WaveTexSideLen;
                return float2(
                    (((float) coordX) + 0.5) / ((float) _WaveTexSideLen), 
                    (((float) coordY) + 0.5) / ((float) _WaveTexSideLen)
                );
            }
            
            float4 frag (VertOut i) : SV_Target
            {
                float pointIntensity = 0;
                
                for (int wave = 0; wave < _MaxWaveIndex; wave++) {
                    float4 waveData = tex2D(_WaveData, waveIndexToUV(wave));
                    float3 waveOrigin = waveData.xyz * _MaxSceneDist;
                    float waveDist = waveData.w * _MaxWaveDist;
                    pointIntensity = max(pointIntensity, intensity(waveOrigin, waveDist, i.ws_vertex.xyz));
                }
                
                return float4(pointIntensity, pointIntensity, pointIntensity, 1.0);
                
            }
            ENDCG
        }
    }
}
