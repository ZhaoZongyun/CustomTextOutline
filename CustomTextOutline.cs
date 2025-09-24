using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

public class CustomTextOutline : BaseMeshEffect
{
    [SerializeField] private bool outline;
    [SerializeField] private Color color;

    public override void ModifyMesh(VertexHelper vh)
    {
        if (!outline || !enabled)
            return;

            for (int i = 0; i < vh.m_Uv1S.Count; i++)
        {
            int n = i / 4;
            int tempIndex = i % 4;
            if (tempIndex == 0)
                vh.m_Uv1S[i] = vh.m_Uv0S[n * 4 + 2];
            else if (tempIndex == 1)
                vh.m_Uv1S[i] = vh.m_Uv0S[n * 4 + 3];
            else if (tempIndex == 2)
                vh.m_Uv1S[i] = vh.m_Uv0S[n * 4 + 0];
            else if (tempIndex == 3)
                vh.m_Uv1S[i] = vh.m_Uv0S[n * 4 + 1];

            vh.m_Uv2S[i] = color;
        }
    }

#if UNITY_EDITOR
    protected override void OnValidate()
    {
        base.OnValidate();

        // 启用、禁用材质关键字
        if (!outline || !enabled)
            graphic.material = null;
            //graphic.material.EnableKeyword("OUTLINE");
        else
            graphic.material = AssetDatabase.LoadAssetAtPath<Material>("Assets/outlineText.mat");
            //graphic.material.DisableKeyword("OUTLINE");
    }
#endif

    protected override void OnDestroy()
    {
        graphic.material = null;
    }
}
