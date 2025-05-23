/*
 * SPDX-FileCopyrightText: 2025 microG Project Team
 * SPDX-License-Identifier: Apache-2.0
 */

package com.google.android.gms.auth.api.identity.internal;

import com.google.android.gms.common.api.Status;
import com.google.android.gms.auth.api.identity.VerifyWithGoogleResult;

interface IVerifyWithGoogleCallback {
    void onVerifed(in Status status, in VerifyWithGoogleResult result);
}