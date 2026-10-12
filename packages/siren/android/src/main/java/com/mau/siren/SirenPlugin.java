package com.mau.siren;

import android.content.Context;


import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SirenPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "ghar_alert/siren");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "start":
                String title = call.argument("title");
                String body = call.argument("body");
                try {
                    SirenService.start(context, title, body);
                } catch (Exception e) {
                    // Foreground service mana ho to seedha bajao (app khula ho tab chalega)
                    SirenPlayer.play(context, null);
                }
                result.success(null);
                break;
            case "stop":
                SirenService.stop(context);
                result.success(null);
                break;
            case "isPlaying":
                result.success(SirenPlayer.isPlaying());
                break;
            default:
                result.notImplemented();
        }
    }
}
