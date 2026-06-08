import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from './services/api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  resumen: any[] = [];
  facturasPendientes: any[] = [];
  facturacionMensual: any[] = [];
  rankingMedicos: any[] = [];

  mongoEstado: any = null;
  historialesPaciente: any[] = [];
  diagnosticosTop: any[] = [];
  medicamentosMongo: any[] = [];
  signosVitales: any[] = [];
  resumenFacet: any = null;
  idPacienteBusqueda = 1;

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

    this.apiService.obtenerDiagnosticosTop().subscribe({
      next: (respuesta) => this.diagnosticosTop = (respuesta.datos || []).slice(0, 8)
    });

    this.apiService.obtenerMedicamentosMongo().subscribe({
      next: (respuesta) => this.medicamentosMongo = (respuesta.datos || []).slice(0, 8)
    });

    this.apiService.obtenerSignosVitales().subscribe({
      next: (respuesta) => this.signosVitales = respuesta.datos || []
    });

    this.apiService.obtenerResumenFacet().subscribe({
      next: (respuesta) => this.resumenFacet = respuesta.datos
    });

    this.apiService.obtenerBackupEstado().subscribe({
      next: (respuesta) => this.backupEstado = respuesta
    });

    this.buscarHistorialesPaciente();
  }

  buscarHistorialesPaciente(): void {
    this.apiService.obtenerHistorialesPaciente(this.idPacienteBusqueda).subscribe({
      next: (respuesta) => this.historialesPaciente = respuesta.datos || [],
      error: () => this.historialesPaciente = []
    });
  }
}
