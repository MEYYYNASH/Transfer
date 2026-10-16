package com.linkora.app;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Button;
import android.widget.ScrollView;
import android.view.View;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(Color.parseColor("#0D0F14"));

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 80, 48, 80);

        // Header Title
        TextView title = new TextView(this);
        title.setText("⚡ LINKORA");
        title.setTextSize(26);
        title.setTextColor(Color.parseColor("#9878FF")); // Primary Accent
        layout.addView(title);

        // Subtitle
        TextView subtitle = new TextView(this);
        subtitle.setText("Secure Cross-Platform File Sharing & Nearby Transfer\nAndroid APK + Windows 10/11 Desktop");
        subtitle.setTextSize(14);
        subtitle.setTextColor(Color.parseColor("#A1A7B7"));
        subtitle.setPadding(0, 16, 0, 48);
        layout.addView(subtitle);

        // Card Container
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackgroundColor(Color.parseColor("#171A23"));
        card.setPadding(36, 36, 36, 36);

        TextView cardTitle = new TextView(this);
        cardTitle.setText("Engine Status: Online");
        cardTitle.setTextSize(16);
        cardTitle.setTextColor(Color.parseColor("#55D6C2")); // Secondary Accent
        card.addView(cardTitle);

        TextView cardBody = new TextView(this);
        cardBody.setText("• Direct Wi-Fi / Hotspot TCP Streaming\n• End-to-End SHA-256 Verification\n• Cloud S3 Presigned Share Links\n• GitHub Releases Auto Updates");
        cardBody.setTextSize(13);
        cardBody.setTextColor(Color.parseColor("#F4F5FA"));
        cardBody.setPadding(0, 16, 0, 24);
        card.addView(cardBody);

        layout.addView(card);

        scrollView.addView(layout);
        setContentView(scrollView);
    }
}
