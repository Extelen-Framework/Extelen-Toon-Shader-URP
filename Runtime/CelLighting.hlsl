void MainLight_half(float3 WorldPos, float3 WorldNormal, out half3 Direction, out half3 Color, out half DistanceAtten, out half ShadowAtten)
{
    #ifdef SHADERGRAPH_PREVIEW
        Direction = half3(-0.5h, 0.5h, -0.5h);
        Color = 1;
        DistanceAtten = 1;
        ShadowAtten = 1;
    #else
        #if SHADOWS_SCREEN 
            half4 clipPos = TransformWorldToClip(WolrdPos);
            half4 shadowCoord = ComputeScreenPos(clipPos);
        #else
            half4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
        #endif

        Light mainLight = GetMainLight(shadowCoord);
        Direction = mainLight.direction;
        Color = mainLight.color;
        DistanceAtten = mainLight.distanceAttenuation;
        ShadowAtten = 0.4h;

        #if !defined(_MAIN_LIGHT_SHADOWS) || defined(_RECEIVE_SHADOWS_OFF)
            ShadowAtten = 1.0h;
        #endif

        #if SHADOWS_SCREEN
            ShadowAtten = SampleScreenSpaceShadowmap(shadowCoord);
        #else 
            ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
            half shadowStrength = GetMainLightShadowStrength();
            ShadowAtten = SampleShadowmap(shadowCoord, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);
        #endif

    #endif
}
void AdditionalLights_half(half3 WorldPosition, half3 WorldNormal, half StepIn, half StepOut, out float Smoothstep, out half3 Color)
{
    half3 _color = 0;
    float _finalSmoothstep = 0;

    #ifndef SHADERGRAPH_PREVIEW

        WorldNormal = normalize(WorldNormal);
        int pixelLightCount = GetAdditionalLightsCount();

        for (int i = 0; i < pixelLightCount; ++i)
        {
            Light light = GetAdditionalLight(i, WorldPosition);
            
            float _smoothstep = smoothstep(StepIn,StepOut,saturate(dot(WorldNormal, light.direction) * light.distanceAttenuation));
            _finalSmoothstep += _smoothstep;
            _color += light.color * _smoothstep;
        }
    #endif

    Smoothstep = clamp(_finalSmoothstep,0,1);
    Color = _color;
}