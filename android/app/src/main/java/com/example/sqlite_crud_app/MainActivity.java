package com.example.sqlite_crud_app;

import android.app.PendingIntent;
import android.content.Intent;
import android.content.IntentFilter;
import android.nfc.NfcAdapter;
import android.nfc.Tag;
import android.nfc.tech.Ndef;
import android.nfc.tech.NdefFormatable;
import android.nfc.tech.NfcA;
import android.nfc.tech.NfcB;
import android.nfc.tech.NfcF;
import android.nfc.tech.NfcV;
import android.nfc.tech.IsoDep;
import android.nfc.tech.MifareClassic;
import android.nfc.tech.MifareUltralight;
import android.os.Bundle;
import android.util.Log;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "nfc_channel";
    private static final String TAG = "NFCMainActivity";

    private NfcAdapter nfcAdapter;
    private PendingIntent nfcPendingIntent;
    private IntentFilter[] nfcIntentFiltersArray;
    private String[][] nfcTechListsArray;
    private MethodChannel methodChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        nfcAdapter = NfcAdapter.getDefaultAdapter(this);
        if (nfcAdapter == null) {
            Log.e(TAG, "❌ NFC is not supported on this device");
            return;
        }

        setupNfcForegroundDispatch();
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "isNfcEnabled":
                    result.success(nfcAdapter != null && nfcAdapter.isEnabled());
                    break;
                case "enableForegroundDispatch":
                    enableForegroundNfcDispatch();
                    result.success(true);
                    break;
                case "disableForegroundDispatch":
                    disableForegroundNfcDispatch();
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private void setupNfcForegroundDispatch() {
        Intent nfcIntent = new Intent(this, getClass());
        nfcIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);

        nfcPendingIntent = PendingIntent.getActivity(
                this,
                0,
                nfcIntent,
                PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        try {
            IntentFilter ndefFilter = new IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED);
            ndefFilter.addDataType("*/*");

            IntentFilter tagFilter = new IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED);
            IntentFilter techFilter = new IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED);

            nfcIntentFiltersArray = new IntentFilter[] { ndefFilter, tagFilter, techFilter };
        } catch (IntentFilter.MalformedMimeTypeException e) {
            Log.e(TAG, "❌ MalformedMimeTypeException", e);
        }

        nfcTechListsArray = new String[][] {
                new String[] { Ndef.class.getName() },
                new String[] { NdefFormatable.class.getName() },
                new String[] { NfcA.class.getName() },
                new String[] { NfcB.class.getName() },
                new String[] { NfcF.class.getName() },
                new String[] { NfcV.class.getName() },
                new String[] { IsoDep.class.getName() },
                new String[] { MifareClassic.class.getName() },
                new String[] { MifareUltralight.class.getName() }
        };
    }

    @Override
    protected void onResume() {
        super.onResume();
        enableForegroundNfcDispatch();
    }

    @Override
    protected void onPause() {
        super.onPause();
        disableForegroundNfcDispatch();
    }

    private void enableForegroundNfcDispatch() {
        if (nfcAdapter != null && nfcAdapter.isEnabled()) {
            nfcAdapter.enableForegroundDispatch(
                    this,
                    nfcPendingIntent,
                    nfcIntentFiltersArray,
                    nfcTechListsArray);
            Log.d(TAG, "✅ NFC Foreground Dispatch ENABLED");
        }
    }

    private void disableForegroundNfcDispatch() {
        if (nfcAdapter != null) {
            nfcAdapter.disableForegroundDispatch(this);
            Log.d(TAG, "❌ NFC Foreground Dispatch DISABLED");
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        String action = intent.getAction();
        Log.d(TAG, "📥 NFC Intent received: " + action);

        if (NfcAdapter.ACTION_NDEF_DISCOVERED.equals(action)
                || NfcAdapter.ACTION_TAG_DISCOVERED.equals(action)
                || NfcAdapter.ACTION_TECH_DISCOVERED.equals(action)) {

            Tag tag = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG);
            if (tag != null) {
                handleNfcTag(tag);
            }
        }
    }

    private void handleNfcTag(Tag tag) {
        String tagId = bytesToHex(tag.getId());
        String[] techList = tag.getTechList();

        Log.d(TAG, "🏷️ Tag ID: " + tagId);
        Log.d(TAG, "🔧 Tech List: " + java.util.Arrays.toString(techList));

        if (methodChannel != null) {
            java.util.Map<String, Object> tagData = new java.util.HashMap<>();
            tagData.put("id", tagId);
            tagData.put("techList", java.util.Arrays.asList(techList));

            methodChannel.invokeMethod("onNfcTagDetected", tagData);
        }
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) {
            result.append(String.format("%02X", b));
        }
        return result.toString();
    }
}
