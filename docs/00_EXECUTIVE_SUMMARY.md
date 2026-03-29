# Cartiqo (SwiftCart) Project Summary

_Generated on 2026-03-25 from the current codebase._

## One-Line Description

Cartiqo is a Flutter + Firebase retail checkout and mall-operations platform: a customer-facing scan-to-bill app and a web portal for admins and mall managers to manage malls, subscriptions, managers, inventory, QR/barcode assets, and sales history.

## What Exists In This Repo

- Flutter app (Android/iOS/Web) built with Provider state management.
- Web portal homepage with Admin login and Mall Manager login entry points.
- Firestore-backed data model for malls, managers, products, barcodes, payments, promotions, announcements, staff activity, support requests, and user profiles.
- CSV export utilities and PDF/print utilities for labels and receipts.
- Firebase Cloud Functions (Node.js/TypeScript) for OTP flows (phone OTP SMS, email OTP signup, password reset OTP) plus scheduled cleanup jobs.

## Primary Roles and Portals

- Customer/App User: signs up/logs in (email/password or OTP), selects a mall, scans items, builds cart, and checks out.
- Admin (Web): manages malls, subscriptions, managers, and operational dashboards; monitors support requests and announcements.
- Mall Manager (Web): logs in via manager ID + password; manages products, barcodes, billing settings, promotions, and sales analytics with CSV export.

