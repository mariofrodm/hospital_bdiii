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
  cargando = true;
  error = '';

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.cargarResumen();
  }

  cargarResumen(): void {
    this.cargando = true;
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
  }
}
