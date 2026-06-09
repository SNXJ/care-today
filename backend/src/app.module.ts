import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { CareModule } from './care/care.module';

@Module({
  imports: [CareModule],
  controllers: [AppController],
})
export class AppModule {}
