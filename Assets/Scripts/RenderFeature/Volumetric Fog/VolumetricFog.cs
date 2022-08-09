using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Post-processing/VolumtricFog")]
    public class VolumetricFog : VolumeComponent, IPostProcessComponent
    {
        [Range(0.0f, 500.0f)]
        public FloatParameter StepCount = new FloatParameter(1f);

        //public ObjectParameter<Transform> cloudTransform = null;
        //[SerializeField]
        //public Transform cloudTransform;

        public bool IsActive() => StepCount.value > 0f && this.active;
        public bool IsTileCompatible() => false;
    }
}
