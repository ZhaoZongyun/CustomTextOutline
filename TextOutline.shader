Shader "GUI/Text Outline"
{
    Properties
    {
        _MainTex ("Font Texture", 2D) = "white" { }
        [Toggle(OUTLINE)]_OutlineEnable ("Enable", float) = 1
        _OutlineSize ("OutlineSize", float) = 0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
        Lighting Off
        Cull Off
        ZTest Always
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "TextOutline"
            CGPROGRAM
            #pragma shader_feature_local OUTLINE
            #pragma vertex vert_shadow
            #pragma fragment frag_shadow
            #pragma multi_compile _ UNITY_SINGLE_PASS_STEREO STEREO_INSTANCING_ON STEREO_MULTIVIEW_ON
            #pragma enable_d3d11_debug_symbols
            #include "UnityCG.cginc"

            struct appdata_t_shadow
            {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;       // UV1
                float4 texcoord1 : TEXCOORD1;       // UV2
                float4 texcoord2 : TEXCOORD2;       // UV3
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f_shadow
            {
                float4 vertex : SV_POSITION;
                float4 texcoord0 : TEXCOORD0;
                float4 texcoord2 : TEXCOORD1;
                float4 worldPosition : TEXCOORD3;
                float4 uvRect : TEXCOOD4;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlineSize;
            float4 _MainTex_TexelSize;
            
            v2f_shadow vert_shadow(appdata_t_shadow IN)
            {
                v2f_shadow OUT;
                
                OUT.worldPosition = IN.vertex;
                
                // 顶点沿对角外扩（UGUI的UV坐标，左上角为0，0，右下角为1，1）
                half x_greater_than_diagnoal = step(IN.texcoord1.x, IN.texcoord0.x);
                half x_less_than_diagnoal = step(IN.texcoord0.x, IN.texcoord1.x);
                half y_greater_than_diagnoal = step(IN.texcoord1.y, IN.texcoord0.y);
                half y_less_than_diagnoral = step(IN.texcoord0.y, IN.texcoord1.y);

                OUT.worldPosition.x += x_greater_than_diagnoal * _OutlineSize;
                OUT.worldPosition.x -= x_less_than_diagnoal * _OutlineSize;
                OUT.worldPosition.y -= y_greater_than_diagnoal * _OutlineSize;
                OUT.worldPosition.y += y_less_than_diagnoral * _OutlineSize;

                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                // UV的范围
                OUT.uvRect = float4(min(IN.texcoord0.xy, IN.texcoord1.xy), max(IN.texcoord0.xy, IN.texcoord1.xy));

                // UV内缩
                OUT.texcoord0 = IN.texcoord0;
                OUT.texcoord0.x -= x_greater_than_diagnoal * _MainTex_TexelSize.x * - _OutlineSize;
                OUT.texcoord0.x += x_less_than_diagnoal * _MainTex_TexelSize.x * - _OutlineSize;
                OUT.texcoord0.y -= y_greater_than_diagnoal * _MainTex_TexelSize.y * - _OutlineSize;
                OUT.texcoord0.y += y_less_than_diagnoral * _MainTex_TexelSize.y * - _OutlineSize;

                // 颜色
                OUT.texcoord2 = IN.texcoord2;
                return OUT;
            }

            // 是否在文字区域内，在，1，不在 0
            fixed IsInRect(float2 uv, v2f_shadow IN)
            {
                float2 isIn = step(IN.uvRect.xy, uv) * step(uv, IN.uvRect.zw);
                return isIn.x * isIn.y;
            }

            float SampleAlpha(int index, v2f_shadow IN)
            {
                float2 sampleOffset[9] =
                {
                    float2(-0.707, 0.707), float2(0, 1), float2(0.707, 0.707),
                    float2(-1, 0), float2(0, 0), float2(1, 0),
                    float2(-0.707, -0.707), float2(0, -1), float2(0.707, -0.707)
                };
                float2 texcoord = IN.texcoord0.xy + _MainTex_TexelSize.xy * float2(sampleOffset[index].xy * _OutlineSize);
                return tex2D(_MainTex, texcoord).a * IsInRect(texcoord, IN);
            }

            fixed4 frag_shadow(v2f_shadow IN) : SV_Target
            {
                #ifdef OUTLINE
                    fixed4 color = IN.texcoord2;
                    color.a = SampleAlpha(0, IN) + SampleAlpha(1, IN) + SampleAlpha(2, IN) + SampleAlpha(3, IN) + SampleAlpha(4, IN)
                    + SampleAlpha(5, IN) + SampleAlpha(6, IN) + SampleAlpha(7, IN) + SampleAlpha(8, IN);
                    clip(color.a - 0.5);
                    return color;
                #else
                    clip(-1);
                    return fixed4(1, 1, 1, 1);
                #endif
            }

            ENDCG
        }

        Pass
        {
            Name "Text"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_SINGLE_PASS_STEREO STEREO_INSTANCING_ON STEREO_MULTIVIEW_ON
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            uniform float4 _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = i.color;
                col.a = tex2D(_MainTex, i.texcoord).a;
                clip(col.a - 0.5);  // 剔除不需要的透明像素，同时可以锐化文字边缘（提高了清晰度）
                return col;
            }
            ENDCG
        }
    }
}