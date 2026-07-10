/** Typed application errors. Transport adapters translate these into HTTP/action results. */

export type AppErrorCode =
  | 'NOT_FOUND'
  | 'FORBIDDEN'
  | 'UNAUTHORIZED'
  | 'VALIDATION'
  | 'CONFLICT'
  | 'TENANT_CONTEXT'
  | 'INTERNAL';

export class AppError extends Error {
  readonly code: AppErrorCode;
  readonly status: number;

  constructor(code: AppErrorCode, message: string, status: number) {
    super(message);
    this.code = code;
    this.status = status;
    this.name = new.target.name;
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Ressource introuvable') {
    super('NOT_FOUND', message, 404);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Authentification requise') {
    super('UNAUTHORIZED', message, 401);
  }
}

export class ForbiddenError extends AppError {
  readonly permission: string | undefined;

  constructor(permission?: string, message = 'Accès refusé') {
    super('FORBIDDEN', message, 403);
    this.permission = permission;
  }
}

export class ValidationError extends AppError {
  readonly issues: unknown;

  constructor(message = 'Données invalides', issues?: unknown) {
    super('VALIDATION', message, 422);
    this.issues = issues;
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Conflit avec une ressource existante') {
    super('CONFLICT', message, 409);
  }
}

export class TenantContextError extends AppError {
  constructor(message = 'Contexte de commune manquant ou invalide') {
    super('TENANT_CONTEXT', message, 500);
  }
}
