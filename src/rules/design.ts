// Proposals only. No combat rules are implemented in sprint 0.
export const DESIGN_PROPOSALS = {
  teamLimit: 6, initialTeamSize: 3, initiativeVariance: 0.05,
  startingTacticalPoints: 2, tacticalPointCap: 5,
} as const;

export const ROLES: Record<number, { name: string; description: string }> = {
  1: { name: 'Control y apoyo', description: 'Una presencia paciente. Sus futuras habilidades buscarán frenar al rival y sostener al equipo.' },
  4: { name: 'Ofensiva', description: 'Presión desde la distancia. Buscar buenos ángulos será la clave de su propuesta táctica.' },
  7: { name: 'Defensa', description: 'Un compañero para mantener la posición. Su propuesta combina protección y desplazamiento del rival.' },
  25: { name: 'Movilidad', description: 'Rápido y ligero. Su propuesta táctica aprovechará los flancos y la parálisis.' },
  12: { name: 'Apoyo y estados', description: 'El valor de cambiar el ritmo. Sus polvos y su movilidad definirán su papel de apoyo.' },
  74: { name: 'Defensa física', description: 'Un ancla para el equipo. Su resistencia permitirá disputar los pasos más estrechos.' },
};
