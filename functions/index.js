/**
 * ADMS Cloud Functions (v2) — Entry Point
 *
 * Registers all Firebase Cloud Functions for the Ambulance Dispatch
 * Management System.
 */

const admin = require("firebase-admin");
admin.initializeApp();

const dispatch = require("./dispatch");
const notifications = require("./notifications");
const invites = require("./invites");
const audit = require("./audit");

// ─── Dispatch Functions ─────────────────────────────────────────────────────

/**
 * When an incident is created, auto-assign the nearest available unit
 * if auto-dispatch is enabled in /systemConfig.
 */
exports.onIncidentCreated = dispatch.onIncidentCreated;

/**
 * When incident status changes to resolved, update unit status back
 * to available and compute response time metrics.
 */
exports.onIncidentStatusChanged = dispatch.onIncidentStatusChanged;

// ─── Notification Functions ──────────────────────────────────────────────────

/**
 * Send push notification to the assigned driver when a unit is dispatched.
 */
exports.onUnitDispatched = notifications.onUnitDispatched;

// ─── Invite Functions ────────────────────────────────────────────────────────

/**
 * Clean up expired invites (older than 7 days, unused).
 * Runs daily via Cloud Scheduler.
 */
exports.cleanupExpiredInvites = invites.cleanupExpiredInvites;

// ─── Audit Functions ─────────────────────────────────────────────────────────

/**
 * Log critical actions to /auditLog when sensitive data changes.
 */
exports.onUserRoleChanged = audit.onUserRoleChanged;