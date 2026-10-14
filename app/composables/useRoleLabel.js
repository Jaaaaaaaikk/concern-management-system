const roleLabels = {
    superadmin: 'Superadmin',
    system_admin: 'System Administrator',
    concern_handler: 'Concern Handler',
    system_monitor: 'System Monitor',
    requestor: 'Requestor'
}

export function roleDisplayName(role) {
    const normalizedRole = String(role || '').trim().toLowerCase()
    return roleLabels[normalizedRole] || role || '-'
}
