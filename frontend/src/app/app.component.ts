import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from './services/api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  resumen: any[] = [];
  facturasPendientes: any[] = [];
  facturacionMensual: any[] = [];
  rankingMedicos: any[] = [];
  mongoEstado: any = null;
  backupEstado: any = null;

  cargando = true;
  error = '';

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.cargarTodo();
  }

  cargarTodo(): void {
    this.cargando = true;
    this.error = '';

    this.apiService.obtenerResumen().subscribe({
      next: (respuesta) => {
        this.resumen = respuesta.datos || [];
        this.cargando = false;
      },
      error: (error) => {
        this.error = error.message || 'No se pudo conectar con la API.';
        this.cargando = false;
      }
    });

    this.apiService.obtenerFacturasPendientes().subscribe({
      next: (respuesta) => this.facturasPendientes = (respuesta.datos || []).slice(0, 8)
    });

    this.apiService.obtenerFacturacionMensual().subscribe({
      next: (respuesta) => this.facturacionMensual = (respuesta.datos || []).slice(0, 8)
    });

    this.apiService.obtenerRankingMedicos().subscribe({
      next: (respuesta) => this.rankingMedicos = (respuesta.datos || []).slice(0, 8)
    });

    this.apiService.obtenerMongoEstado().subscribe({
      next: (respuesta) => this.mongoEstado = respuesta
    });

    this.apiService.obtenerBackupEstado().subscribe({
      next: (respuesta) => this.backupEstado = respuesta
    });
  }
}
