﻿Shader "PS1/Emission"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (0.5, 0.5, 0.5, 1)
        _GeoRes("Geometric Resolution", Float) = 70
        [HDR]_EmissionColor("EmissonColor", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase// nolightmap nodirlightmap nodynlightmap novertexlight
            // shadow helper functions and macros
            #include "AutoLight.cginc"

            struct v2f
            {
                SHADOW_COORDS(1) // put shadows data into TEXCOORD1
                fixed3 diff : COLOR0;
                fixed3 ambient : COLOR1;
                float4 pos : SV_POSITION;
                float3 texcoord : TEXCOORD;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _EmissionColor;
            float _GeoRes;

            v2f vert(appdata_base v)
            {
                v2f o;
                //o.pos = UnityObjectToClipPos(v.vertex);
                float4 wp = mul(UNITY_MATRIX_MV, v.vertex);
                wp.xyz = floor(wp.xyz * _GeoRes) / _GeoRes;

                float4 sp = mul(UNITY_MATRIX_P, wp);
                o.pos = sp;

                //o.uv = v.texcoord;
                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.texcoord = float3(uv * sp.w, sp.w);
                
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0.rgb;
                o.ambient = ShadeSH9(half4(worldNormal,1));
                // compute shadows data
                TRANSFER_SHADOW(o)

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.texcoord.xy / i.texcoord.z;
                float4 col = tex2D(_MainTex, uv) * _Color;
                // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
                fixed shadow = SHADOW_ATTENUATION(i);
                // darken light's illumination with shadow, keep ambient intact
                fixed3 lighting = i.diff * shadow + i.ambient;
                col.rgb *= lighting;
                col += _EmissionColor;
                return col;
            }
            ENDCG
        }

        Pass
        {
                Tags {"LightMode" = "ForwardAdd"}
                Blend One One
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdadd_fullshadows

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float3 texcoord : TEXCOORD0;
                    float3 normal : TEXCOORD1;
                    float3 wPos : TEXCOORD2;
                    LIGHTING_COORDS(3, 4)
                    //SHADOW_COORDS(2)
                };
                
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float4 _Color;
                float _GeoRes;

                v2f vert(appdata_base v)
                {
                    v2f o;
                    float4 wp = mul(UNITY_MATRIX_MV, v.vertex);
                    wp.xyz = floor(wp.xyz * _GeoRes) / _GeoRes;

                    float4 sp = mul(UNITY_MATRIX_P, wp);
                    o.pos = sp;
                    //o.pos = UnityObjectToClipPos(data.vertex);

                    float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    o.texcoord = float3(uv * sp.w, sp.w);

                    o.wPos = mul(unity_ObjectToWorld, v.vertex);

                    o.normal = v.normal;

                    //TRANSFER_SHADOW(o);
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

                float4 frag(v2f i) :SV_Target
                {
                    float2 uv = i.texcoord.xy / i.texcoord.z;

                    float3 N = normalize(UnityObjectToWorldNormal(i.normal));//////

                    float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.wPos.xyz, _WorldSpaceLightPos0.w));

                    float atten = LIGHT_ATTENUATION(i);

                    float4 col = tex2D(_MainTex, uv) * _Color;

                    col.rgb *= _LightColor0.rgb * saturate(dot(N, L)) * atten;

                    return col;
                }
                ENDCG
        }

        Pass
        {
            Name "META"
            Tags {"LightMode" = "Meta"}
            Cull Off
            CGPROGRAM

            #include "UnityStandardMeta.cginc"
            #pragma vertex vert_meta
            #pragma fragment frag_meta_custom

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 wPos : TEXCOORD2;
                LIGHTING_COORDS(3, 4)
                //SHADOW_COORDS(2)
            };

            fixed4 frag_meta_custom(v2f i) : SV_Target
            {
                // Colors                
                fixed4 col = (1, 0, 0, 0); // The emission color

                // Calculate emission
                UnityMetaInput metaIN;
                    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
                    metaIN.Albedo = col.rgb;
                    metaIN.Emission = col.rgb;
                    return UnityMetaFragment(metaIN);

                return col;
            }

            ENDCG
        }

        // shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    FallBack "Diffuse"
}