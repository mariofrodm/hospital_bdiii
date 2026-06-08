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

  obtenerBackupEstado(): Observable<any> {
    return this.http.get(`${this.apiUrl}/backup/estado`);
  }
}
