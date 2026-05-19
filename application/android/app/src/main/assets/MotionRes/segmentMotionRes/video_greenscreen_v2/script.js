/*** light-js-config
***/
// 加载 AEJSBridge.js
light.execute("light://js/AEJSBridge.js");

// 素材逻辑函数体
(function () {
    // 定义global对象
    var global = global || (function () {return this;}());
    // 定义素材对象
    var template = global.template || (function () {return {};}());
    // 并挂在global对象下
    global.template = template;
    // 定义需要用到的resource
    var resourcePool = {
    }
     //初始化一个jsonObject,
    template.uniformJson = {
        "uniformMap": {
            "green_seg_chromakey": {
                "green_params": [0.4, 0.0, 1.0, 0.0], // [similarity, deshadow, corrosion,]
                "tex_rect": [0.0, 0.0, 720.0, 1280.0],
                "average_green": [0.0, 1.0, 0.0, 0.0]
            },
            "Corrosion": {
                "tex_rect": [0.0, 0.0, 720.0, 1280.0],
                "corrosion": [1.0, 0.0, 0.0, 0.0] // [corrosion,]
            },
            "Merge": {
                "tex_rect": [0.0, 0.0, 720.0, 1280.0],
                "merge_params": [1.0, 0.1, 0.08, 0.0], // [corrosion, despill, smooth]
                "tex_protect_rect": [0.0, 0.0, 0.0, 0.0] // protect area
            }
        }
    }
    // 也挂在global对象下
    global.resourcePool = resourcePool;


//    // 订阅InputEvent事件
    template.onInputEvent = function(params) {
        // //相似度对应similarity， 平滑度对应smooth， 边缘消除强度对应 corrosion， 灰度比例对应 despill， 去阴影对应 deshadow
        var GreenSeg_jsonDataParams = params["event.script.lightsdk.GreenScreenSetGreenParamsV2"];
     
        if (GreenSeg_jsonDataParams) {

            var similarity_value = GreenSeg_jsonDataParams["green_params_v2"][0];
            var smooth_value = GreenSeg_jsonDataParams["green_params_v2"][1];
            var corrosion_value = GreenSeg_jsonDataParams["green_params_v2"][2];
            var despill_value = GreenSeg_jsonDataParams["green_params_v2"][3];
            var deshadow_value = GreenSeg_jsonDataParams["green_params_v2"][4];

            template.uniformJson.uniformMap.green_seg_chromakey.green_params[0] = similarity_value;
            template.uniformJson.uniformMap.green_seg_chromakey.green_params[1] = deshadow_value;
            template.uniformJson.uniformMap.green_seg_chromakey.green_params[2] = corrosion_value; // corrosion
            template.uniformJson.uniformMap.Corrosion.corrosion[0] = corrosion_value; // corrosion
            template.uniformJson.uniformMap.Merge.merge_params[0] = corrosion_value; // corrosion
            template.uniformJson.uniformMap.Merge.merge_params[1] = despill_value; // despill
            template.uniformJson.uniformMap.Merge.merge_params[2] = smooth_value; // smooth          
        }
        // 绿幕保护区域
        var Merge_jsonDataProtectRect = params["event.script.lightsdk.GreenScreenSetProtectRect"];
        
        if (Merge_jsonDataProtectRect) {
        
            template.uniformJson.uniformMap.Merge.tex_protect_rect[0] = Merge_jsonDataProtectRect["tex_protect_rect"][0];
            template.uniformJson.uniformMap.Merge.tex_protect_rect[1] = 1.0 - Merge_jsonDataProtectRect["tex_protect_rect"][1];
            template.uniformJson.uniformMap.Merge.tex_protect_rect[2] = Merge_jsonDataProtectRect["tex_protect_rect"][2];
            template.uniformJson.uniformMap.Merge.tex_protect_rect[3] = 1.0 - Merge_jsonDataProtectRect["tex_protect_rect"][3];
        }
    }

    // 素材初始化, 对应c++的configure
    template.onTemplateInit = function (entityManager, eventManager) {
        template.customGraph = light.getComponent(
          entityManager.getEntityByName("CustomGraph"),
          "CustomGraph"
        );
    }
    // 对应c++的update
    template.onFrameUpdate = function (currentTime, entityManager, eventManager) {
        //将得到的uniformJson传递到自定义滤镜链中
        var surfaceWidth = light.DeviceUtils.GetSurfaceWidth(entityManager);
        var surfaceHeight = light.DeviceUtils.GetSurfaceHeight(entityManager);
        
        template.uniformJson.uniformMap.green_seg_chromakey.tex_rect[2] = surfaceWidth;
        template.uniformJson.uniformMap.green_seg_chromakey.tex_rect[3] = surfaceHeight;

        template.uniformJson.uniformMap.Corrosion.tex_rect[2] = surfaceWidth;
        template.uniformJson.uniformMap.Corrosion.tex_rect[3] = surfaceHeight;

        template.uniformJson.uniformMap.Merge.tex_rect[2] = surfaceWidth;
        template.uniformJson.uniformMap.Merge.tex_rect[3] = surfaceHeight;

        template.customGraph.uniformJson = JSON.stringify(template.uniformJson);
    }
}());
