import csv
import json
import random
from datetime import datetime

ARCHIVO_ENTRADA = "citas_atendidas_mongo.csv"
ARCHIVO_SALIDA = "historiales_clinicos.json"


diagnosticos_por_especialidad = {
    "Medicina General": [
        ("J00", "Resfriado común"),
        ("R51", "Cefalea"),
        ("K29", "Gastritis"),
        ("R50", "Fiebre no especificada"),
        ("M54", "Dolor lumbar")
    ],
    "Cardiología": [
        ("I10", "Hipertensión esencial"),
        ("I20", "Angina de pecho"),
        ("I49", "Arritmia cardiaca"),
        ("R07", "Dolor torácico"),
        ("I50", "Insuficiencia cardiaca")
    ],
    "Pediatría": [
        ("J06", "Infección aguda de vías respiratorias superiores"),
        ("A09", "Gastroenteritis infecciosa"),
        ("R50", "Fiebre"),
        ("J45", "Asma pediátrica"),
        ("L20", "Dermatitis atópica")
    ],
    "Dermatología": [
        ("L70", "Acné"),
        ("L30", "Dermatitis"),
        ("B35", "Micosis superficial"),
        ("L40", "Psoriasis"),
        ("L50", "Urticaria")
    ],
    "Traumatología": [
        ("S93", "Esguince de tobillo"),
        ("M25", "Dolor articular"),
        ("S52", "Fractura de antebrazo"),
        ("M54", "Dolor de espalda"),
        ("S80", "Contusión de rodilla")
    ]
}


medicamentos_por_diagnostico = {
    "Resfriado común": ["Acetaminofén", "Loratadina", "Solución salina nasal"],
    "Cefalea": ["Ibuprofeno", "Acetaminofén"],
    "Gastritis": ["Omeprazol", "Sucralfato"],
    "Fiebre no especificada": ["Acetaminofén", "Ibuprofeno"],
    "Dolor lumbar": ["Naproxeno", "Metocarbamol"],

    "Hipertensión esencial": ["Losartán", "Amlodipino"],
    "Angina de pecho": ["Nitroglicerina", "Aspirina"],
    "Arritmia cardiaca": ["Bisoprolol", "Amiodarona"],
    "Dolor torácico": ["Aspirina", "Nitroglicerina"],
    "Insuficiencia cardiaca": ["Furosemida", "Enalapril"],

    "Infección aguda de vías respiratorias superiores": ["Acetaminofén", "Loratadina"],
    "Gastroenteritis infecciosa": ["Suero oral", "Probióticos"],
    "Fiebre": ["Acetaminofén pediátrico"],
    "Asma pediátrica": ["Salbutamol", "Budesonida"],
    "Dermatitis atópica": ["Hidrocortisona tópica", "Loratadina"],

    "Acné": ["Peróxido de benzoilo", "Clindamicina tópica"],
    "Dermatitis": ["Hidrocortisona tópica", "Cetirizina"],
    "Micosis superficial": ["Clotrimazol", "Terbinafina"],
    "Psoriasis": ["Calcipotriol", "Betametasona tópica"],
    "Urticaria": ["Cetirizina", "Loratadina"],

    "Esguince de tobillo": ["Ibuprofeno", "Diclofenaco gel"],
    "Dolor articular": ["Naproxeno", "Diclofenaco"],
    "Fractura de antebrazo": ["Acetaminofén", "Ibuprofeno"],
    "Dolor de espalda": ["Naproxeno", "Metocarbamol"],
    "Contusión de rodilla": ["Ibuprofeno", "Diclofenaco gel"]
}


examenes_por_especialidad = {
    "Medicina General": ["Hemograma completo", "Glucosa en ayunas", "Examen general de orina"],
    "Cardiología": ["Electrocardiograma", "Ecocardiograma", "Perfil lipídico"],
    "Pediatría": ["Hemograma pediátrico", "Examen de heces", "Prueba de influenza"],
    "Dermatología": ["Biopsia de piel", "Cultivo micológico", "Evaluación dermatoscópica"],
    "Traumatología": ["Radiografía", "Resonancia magnética", "Ultrasonido musculoesquelético"]
}


motivos_por_especialidad = {
    "Medicina General": [
        "Consulta por malestar general",
        "Dolor de cabeza recurrente",
        "Fiebre y congestión nasal",
        "Dolor abdominal",
        "Control médico general"
    ],
    "Cardiología": [
        "Dolor en el pecho",
        "Palpitaciones frecuentes",
        "Control de presión arterial",
        "Dificultad para respirar al esfuerzo",
        "Seguimiento cardiológico"
    ],
    "Pediatría": [
        "Fiebre en paciente pediátrico",
        "Tos persistente",
        "Control de crecimiento",
        "Dolor abdominal infantil",
        "Seguimiento pediátrico"
    ],
    "Dermatología": [
        "Lesión en la piel",
        "Picazón persistente",
        "Brote cutáneo",
        "Control dermatológico",
        "Manchas en la piel"
    ],
    "Traumatología": [
        "Dolor articular",
        "Lesión posterior a caída",
        "Dolor de rodilla",
        "Dolor lumbar",
        "Control traumatológico"
    ]
}


def grupo_etario(edad):
    if edad < 13:
        return "niño"
    if edad < 18:
        return "adolescente"
    if edad < 60:
        return "adulto"
    return "adulto_mayor"


def generar_signos_vitales(edad):
    return {
        "presion_sistolica": random.randint(95, 145 if edad >= 18 else 120),
        "presion_diastolica": random.randint(60, 95 if edad >= 18 else 80),
        "frecuencia_cardiaca": random.randint(65, 110 if edad < 18 else 95),
        "temperatura": round(random.uniform(36.1, 38.4), 1),
        "peso_kg": round(random.uniform(18, 85) if edad < 18 else random.uniform(50, 95), 1),
        "altura_cm": round(random.uniform(100, 170) if edad < 18 else random.uniform(150, 185), 1)
    }


def generar_datos_especialidad(especialidad):
    if especialidad == "Cardiología":
        return {
            "riesgo_cardiovascular": random.choice(["bajo", "moderado", "alto"]),
            "dolor_toracico": random.choice([True, False]),
            "antecedentes_familiares": random.choice([True, False])
        }

    if especialidad == "Dermatología":
        return {
            "tipo_lesion": random.choice(["mancha", "roncha", "placa", "pápula", "descamación"]),
            "zona_afectada": random.choice(["brazo", "rostro", "cuello", "espalda", "pierna"]),
            "tiempo_evolucion": random.choice(["3 días", "1 semana", "2 semanas", "1 mes"])
        }

    if especialidad == "Pediatría":
        return {
            "peso_percentil": random.randint(10, 95),
            "talla_percentil": random.randint(10, 95),
            "vacunas_al_dia": random.choice([True, False])
        }

    if especialidad == "Traumatología":
        return {
            "zona_lesion": random.choice(["rodilla", "tobillo", "hombro", "espalda", "muñeca"]),
            "dolor_escala": random.randint(1, 10),
            "requiere_inmovilizacion": random.choice([True, False])
        }

    return {
        "requiere_seguimiento": random.choice([True, False]),
        "dias_reposo": random.randint(0, 5)
    }


def convertir_fecha(fecha, hora_inicio):
    valor = f"{fecha}T{hora_inicio}"
    return datetime.fromisoformat(valor).isoformat()


def normalizar_fila(row):
    return {k.strip().lower(): v for k, v in row.items()}


def generar_historial(row):
    row = normalizar_fila(row)

    especialidad = row["especialidad"]
    edad = int(row["edad_paciente"])
    diagnostico_codigo, diagnostico_desc = random.choice(
        diagnosticos_por_especialidad.get(especialidad, diagnosticos_por_especialidad["Medicina General"])
    )

    medicamentos_base = medicamentos_por_diagnostico.get(diagnostico_desc, ["Acetaminofén"])
    medicamentos = [
        {
            "nombre": med,
            "dosis": random.choice(["250 mg", "500 mg", "1 tableta", "5 ml", "10 mg"]),
            "frecuencia": random.choice(["Cada 8 horas", "Cada 12 horas", "Cada 24 horas"]),
            "duracion": random.choice(["3 días", "5 días", "7 días", "14 días", "30 días"])
        }
        for med in random.sample(medicamentos_base, k=min(len(medicamentos_base), random.randint(1, 2)))
    ]

    examenes_disponibles = examenes_por_especialidad.get(especialidad, examenes_por_especialidad["Medicina General"])
    examenes = [
        {
            "nombre": examen,
            "prioridad": random.choice(["normal", "alta"]),
            "observaciones": "Solicitado como apoyo diagnóstico"
        }
        for examen in random.sample(examenes_disponibles, k=random.randint(1, min(2, len(examenes_disponibles))))
    ]

    return {
        "id_cita": int(row["id_cita"]),
        "id_paciente": int(row["id_paciente"]),
        "id_medico": int(row["id_medico"]),
        "id_especialidad": int(row["id_especialidad"]),
        "especialidad": especialidad,
        "fecha_consulta": convertir_fecha(row["fecha_cita"], row["hora_inicio"]),
        "edad_paciente": edad,
        "grupo_etario": grupo_etario(edad),
        "motivo_consulta": random.choice(motivos_por_especialidad.get(especialidad, motivos_por_especialidad["Medicina General"])),
        "signos_vitales": generar_signos_vitales(edad),
        "diagnosticos": [
            {
                "codigo": diagnostico_codigo,
                "descripcion": diagnostico_desc,
                "tipo": "principal"
            }
        ],
        "medicamentos": medicamentos,
        "examenes_solicitados": examenes,
        "notas_adicionales": random.choice([
            "Paciente estable al finalizar la consulta.",
            "Se recomienda seguimiento según evolución.",
            "Se brindan indicaciones médicas generales.",
            "Paciente comprende indicaciones y tratamiento.",
            "Se solicita control en próxima cita."
        ]),
        "datos_especialidad": generar_datos_especialidad(especialidad),
        "created_at": datetime.now().isoformat(),
        "updated_at": None
    }


def main():
    historiales = []

    with open(ARCHIVO_ENTRADA, mode="r", encoding="utf-8-sig", newline="") as archivo:
        lector = csv.DictReader(archivo)

        for row in lector:
            historiales.append(generar_historial(row))

    if len(historiales) < 150:
        raise ValueError("El archivo CSV debe contener al menos 150 citas atendidas.")

    historiales = historiales[:150]

    with open(ARCHIVO_SALIDA, mode="w", encoding="utf-8") as archivo:
        json.dump(historiales, archivo, ensure_ascii=False, indent=2)

    print(f"Archivo generado correctamente: {ARCHIVO_SALIDA}")
    print(f"Total de historiales generados: {len(historiales)}")


if __name__ == "__main__":
    main()