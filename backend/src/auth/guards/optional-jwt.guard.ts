import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Like JwtAuthGuard but never throws when a token is absent or invalid.
 * Used on analytics endpoints so anonymous (pre-auth) callers still
 * receive results. The controller is responsible for branching on
 * req.user being defined.
 */
@Injectable()
export class OptionalJwtGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    return super.canActivate(context) as any;
  }

  handleRequest<TUser = any>(
    err: any,
    user: any,
    _info: any,
    _context: ExecutionContext,
  ): TUser {
    // Swallow errors and missing-token cases; return null so req.user is
    // falsy in the controller.
    if (err || !user) return null as unknown as TUser;
    return user as TUser;
  }
}
