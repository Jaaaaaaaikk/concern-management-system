const roleLabels = {
    superadmin: 'Superadmin',
    admin: 'Concern Handler',
    user: 'Requestor'
}

export function roleDisplayName(role) {
    const normalizedRole = String(role || '').trim().toLowerCase()
    return roleLabels[normalizedRole] || role || '-'
}
