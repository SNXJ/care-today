import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  health() {
    return {
      status: 'ok',
      service: 'care-today-backend',
      medicalBoundary:
        'CareToday only supports life companionship, appointment organization, and family collaboration. It does not provide diagnosis, treatment advice, or medication judgment.',
    };
  }
}
