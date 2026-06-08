import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface RespuestaApi<T> {
  ok: boolean;
  total?: number;
  datos?: T;
  mensaje?: string;
  error?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly apiUrl = 'http://localhost:3000/api';

  constructor(private http: HttpClient) {}

  obtenerResumen(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/catalogos/resumen`);
  }

  obtenerFacturasPendientes(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/reportes/facturas-pendientes`);
  }

  obtenerFacturacionMensual(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/reportes/facturacion-mensual`);
  }

  obtenerRankingMedicos(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/reportes/ranking-medicos-trimestral`);
  }

  obtenerMongoEstado(): Observable<any> {
    return this.http.get(`${this.apiUrl}/mongo/estado`);
  }

  obtenerHistorialesPaciente(idPaciente: number): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/mongo/historiales/paciente/${idPaciente}`);
  }

  obtenerDiagnosticosTop(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/mongo/reportes/diagnosticos-top`);
  }

  obtenerMedicamentosMongo(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/mongo/reportes/medicamentos`);
  }

  obtenerSignosVitales(): Observable<RespuestaApi<any[]>> {
    return this.http.get<RespuestaApi<any[]>>(`${this.apiUrl}/mongo/reportes/signos-vitales`);
  }

  obtenerResumenFacet(): Observable<any> {
    return this.http.get(`${this.apiUrl}/mongo/reportes/resumen-facet`);
  }

  obtenerBackupEstado(): Observable<any> {
    return this.http.get(`${this.apiUrl}/backup/estado`);
  }

  registrarPago(datos: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/operaciones/registrar-pago`, datos);
  }

  cancelarCita(datos: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/operaciones/cancelar-cita`, datos);
  }

  refrescarMaterializadas(): Observable<any> {
    return this.http.post(`${this.apiUrl}/operaciones/refresh-materializadas`, {});
  }
}
