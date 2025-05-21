/*
 * Copyright (C) 2013-2017 microG Project Team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.microg.gms.checkin;

import static android.app.PendingIntent.FLAG_UPDATE_CURRENT;
import static android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET;
import static android.os.Build.VERSION.SDK_INT;
import static org.microg.gms.checkin.CheckinService.EXTRA_FORCE_CHECKIN;
import static org.microg.gms.checkin.CheckinService.REGULAR_CHECKIN_INTERVAL;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.NetworkRequest;
import android.util.Log;

import androidx.core.app.PendingIntentCompat;
import androidx.legacy.content.WakefulBroadcastReceiver;

import org.microg.gms.common.ForegroundServiceContext;
import org.microg.gms.droidguard.core.DroidGuardPreferences;
import org.microg.gms.gcm.GcmPrefs;
import org.microg.gms.location.LocationSettings;
import org.microg.gms.profile.ProfileManager;
import org.microg.gms.safetynet.SafetyNetPreferences;

import java.util.Objects;

public class TriggerReceiver extends WakefulBroadcastReceiver {
    private static final String TAG = "GmsCheckinTrigger";
    private static boolean registered = false;

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            boolean force = "android.provider.Telephony.SECRET_CODE".equals(intent.getAction());

            if (CheckinPreferences.isEnabled(context) || force) {
                if (LastCheckinInfo.read(context).getLastCheckin() > System.currentTimeMillis() - REGULAR_CHECKIN_INTERVAL && !force) {
                    CheckinService.schedule(context);
                    return;
                }

                ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
                NetworkInfo networkInfo = cm.getActiveNetworkInfo();
                if (networkInfo != null && networkInfo.isConnected() || force) {
                    Intent subIntent = new Intent(context, CheckinService.class);
                    subIntent.putExtra(EXTRA_FORCE_CHECKIN, force);
                    startWakefulService(new ForegroundServiceContext(context), subIntent);
                } else if (SDK_INT >= 23) {
                    // no network, register a network callback to retry when we have internet
                    NetworkRequest networkRequest = new NetworkRequest.Builder()
                            .addCapability(NET_CAPABILITY_INTERNET)
                            .build();
                    Intent i = new Intent(context, TriggerReceiver.class);
                    PendingIntent pendingIntent = PendingIntentCompat.getBroadcast(context, 0, i, FLAG_UPDATE_CURRENT, true);
                    cm.registerNetworkCallback(networkRequest, pendingIntent);
                }
            } else {
                Log.d(TAG, "Ignoring " + intent + ": checkin is disabled");
            }
        } catch (Exception e) {
            Log.w(TAG, e);
        }

        // Initial setup for Pi OS
        if(Objects.equals(intent.getAction(), Intent.ACTION_BOOT_COMPLETED)) {
            if(!CheckinPreferences.isEnabled(context)) {
                CheckinPreferences.setEnabled(context, true);
                ProfileManager.INSTANCE.setProfile(context, "bullhead_27");
                GcmPrefs.Companion.setEnabled(context, true);
                SafetyNetPreferences.setEnabled(context, true);
                DroidGuardPreferences.setEnabled(context, true);

                LocationSettings settings = new LocationSettings(context);
//                settings.setOnlineSourceId("beacondb");
                settings.setCustomEndpoint("https://api.positon.xyz/?key=74600654-2aec-11ef-aa95-3b7218da6865");
                settings.setWifiIchnaea(true);
                settings.setWifiLearning(true);
                settings.setWifiMoving(true);
                settings.setCellIchnaea(true);
                settings.setCellLearning(true);
            }
        }
    }
}
