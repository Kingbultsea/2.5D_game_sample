// Based on Unlit.shader from URP v10.2
Shader "Universal Render Pipeline/Unlit Sprite"
{
    Properties
    {
        // 主纹理，用于对象的表面
        _MainTex("Texture", 2D) = "white" {}
        // 用于透明度裁剪的阈值。当纹理的透明度低于这个值时，像素将不会被渲染。
        _Cutoff("Alpha Cutout", Range(0.0, 1.0)) = 0.5

        // 这些是不在编辑器中显示，但在内部用于配置渲染状态的属性。

        // BlendMode
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("Src", Float) = 1.0
        [HideInInspector] _DstBlend("Dst", Float) = 0.0
        //[HideInInspector] _ZWrite("ZWrite", Float) = 1.0
        //[HideInInspector] _Cull("__cull", Float) = 2.0

        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        // [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        // [HideInInspector] _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
        [HideInInspector] _SampleGI("SampleGI", float) = 0.0 // needed from bakedlit
    }

    // 每个SubShader中可以包含多个Pass，每个Pass定义了一次绘制操作
    SubShader
    {
        // 用于定义Shader的一些基础设置
        Tags
        {
            // 定义这是一个不透明类型的渲染
            "RenderType" = "Opaque"
            // 不受投影影响
            "IgnoreProjector" = "True"
            // 指定这个Shader属于Universal Render Pipeline
            "RenderPipeline" = "UniversalPipeline"
            // 这个标签指定了在Unity的Shader编辑器中预览材质时应该使用的几何形状类型。
            // "Plane" 表示该Shader将在一个平面上被预览。这有助于在开发过程中快速查看材质的表现
            "PreviewType" = "Plane"
            // 这是指Shader模型（Shader Model），它定义了Shader可以使用的图形功能级别。
            // "4.5" 是一个较高的级别，支持较为复杂的渲染技术和更多的图形API功能。这通常意味着Shader将利用较新的硬件能力。
            "ShaderModel" = "4.5"
        }

        //  LOD代表“Level of Detail”，即细节级别。
        // 在Shader中设置LOD值是为了优化性能，允许引擎根据设备性能或对象与摄像机的距离来选择不同复杂性的Shader代码。
        // LOD 100表示这个Shader在中等的细节级别下被使用，如果有多个LOD级别，较低的数字代表更高的细节和通常更高的性能需求。
        LOD 100

        // 这是混合模式的设置，它控制如何将物体的像素与背景像素结合。
        // [_SrcBlend] 和 [_DstBlend] 是参数化的形式，意味着具体的混合因子是通过这些参数来设置的，它们在Shader的属性部分或通过脚本在运行时可以被定义。
        // 混合因子决定了源颜色（即物体本身的颜色）和目标颜色（即已在屏幕上的颜色，来自于其他物体的颜色）如何相互影响。
        Blend [_SrcBlend][_DstBlend]
        // 这个设置指示Shader在渲染时更新深度缓冲区。
        // 深度缓冲区用于记录图像的深度信息，帮助决定哪些对象的部分应该被其他部分遮挡。
        // "On" 表示启用深度写入，这是处理遮挡关系时非常重要的。
        ZWrite On
        // 剔除是3D渲染中一种优化技术，用于不渲染面向远离摄像机的面（背面）。
        // "Cull Off" 表示关闭这种剔除，无论面的朝向如何，都会渲染。
        // 这在某些情况下很有用，比如绘制双面材质或当你不希望由于面的方向问题导致渲染错误时。
        Cull Off

        Pass
        {
            // 这个Pass用于基本的无光照渲染
            Name "Unlit"

            // 高级着色语言（HLSL）部分的标记，指定了顶点和片段着色器的代码。
            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            // 这些指令定义了编译Shader时所针对的图形API版本。4.5通常用于更高级的渲染特性和较新的硬件，而2.0用于向后兼容较旧设备。
            #pragma target 4.5

            // 函数处理顶点数据，计算顶点位置和传递UV坐标和颜色
            #pragma vertex vert
            // 函数处理片段数据，从纹理中取色并应用顶点颜色，还包括基于_AlphaClip值的裁剪逻辑。
            #pragma fragment frag

            // 这些指令用于启用或禁用特定的Shader功能，只在片段着色器中生效。当这些特性被定义时，编译器会为Shader生成多个版本，每个版本都针对特定的功能组合进行优化。
            //这样可以在运行时根据需要启用或禁用特定功能，而不必重新编译整个Shader。

            // 启用Alpha测试，用于根据透明度阈值丢弃某些像素，常用于实现复杂形状的贴图。
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // 启用预乘Alpha，这种处理方式在Alpha混合时，可以减少边缘的颜色失真。
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Unity defined keywords
            // 此指令启用多重编译以支持雾效。它生成不同的Shader变体，每个变体都有或没有雾效的支持。这允许Unity在运行时根据场景是否启用雾效来选择合适的Shader变体。
            #pragma multi_compile_fog

            // 这些是用于支持实例化渲染的编译指令。
            #pragma multi_compile_instancing // 为Shader生成支持GPU实例化的版本。实例化是一种技术，允许用单个绘制调用同时渲染多个对象的副本，大大减少CPU到GPU的绘制调用，提高渲染效率
            #pragma multi_compile _ DOTS_INSTANCING_ON  // 这是用于Unity的数据导向技术栈（DOTS）中的实例化支持。在使用DOTS时，这允许Shader更好地与Unity的ECS（实体组件系统）集成。

            // 这是一个预处理指令，用于在当前Shader文件中包含另一个文件的内容。UnlitInput.hlsl 文件通常包含有关如何处理输入数据（如顶点数据、UV坐标等）的通用函数和宏定义。这样做的好处是可以重用代码，避免在多个Shader文件中重复相同的代码片段。
            #include "UnlitInput.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.color = input.color;
                output.vertex = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half3 color = texColor.rgb * input.color.rgb;
                half alpha = texColor.a * input.color.a;
                clip(alpha - _Cutoff);

                #ifdef _ALPHAPREMULTIPLY_ON
                color *= alpha;
                #endif

                color = MixFog(color, input.fogCoord);
                return half4(color, alpha);
            }
            ENDHLSL
        }
        Pass
        {
            // 这个Pass用于渲染深度信息，常用于阴影计算或Z-Prepass。
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "UnlitInput.hlsl"
            #include "DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            // 这个Pass用于烘焙光照数据，通常在烘焙过程中使用，不用于普通渲染。
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            #include "UnlitInput.hlsl"
            #include "UnlitMetaPass.hlsl"
            ENDHLSL
        }
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            "PreviewType" = "Plane"
            "ShaderModel" = "2.0"
        }
        LOD 100

        Blend [_SrcBlend][_DstBlend]
        ZWrite On
        Cull Off

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnlitInput.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half3 color = texColor.rgb * input.color.rgb;
                half alpha = texColor.a * input.color.a;
                clip(alpha - _Cutoff);

                #ifdef _ALPHAPREMULTIPLY_ON
                color *= alpha;
                #endif

                color = MixFog(color, input.fogCoord);
                alpha = OutputAlpha(alpha, _Surface);

                return half4(color, alpha);
            }
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "UnlitInput.hlsl"
            #include "DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            #include "UnlitInput.hlsl"
            #include "UnlitMetaPass.hlsl"
            ENDHLSL
        }
    }

    // 指定当当前Shader无法在某些硬件上运行时，将回退到的Shader。
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    // CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.UnlitShader"
}