using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Post-processing/VolumtricFog")]
    public class VolumetricFog : VolumeComponent, IPostProcessComponent
    {
        [Range(0.0f, 100.0f)]
        public FloatParameter StepCount = new FloatParameter(1f);

        public bool IsActive() => this.active;
        public bool IsTileCompatible() => false;
    }
}
