clear
global censo cd "F:\Laptop2016\Bases\Censo_Escolar\Censo2019"
global censo20 cd "F:\Laptop2016\Bases\Censo_Escolar\Censo2020"
global temp cd "D:\Trabajo\Consultoria\USE_MINEDU\Set-Nov21\Oct-Nov-CentrosDigitales-Cesar\Proyecto_centros_digitales\temp"
global result cd "D:\Trabajo\Consultoria\USE_MINEDU\Set-Nov21\Oct-Nov-CentrosDigitales-Cesar\Proyecto_centros_digitales\result"
global dist cd "D:\Trabajo\Consultoria\TrabajaPeru\Trabajo\Trabajadas_stata"

**********************************
* Base de datos del local_lineal *
**********************************
$censo
use codlocal gestion codgeo dpto prov p101 p104 p105 p106 p107 p111_1- p111_6 p204 p204_si p301_qaula p605 p606 p702 p703 p708 p709 p711 p712 using "local_lineal.dta",clear

foreach x of varlist p101-p712 {
destring `x',replace
}
* Reemplazando "0" por "2"
foreach x of varlist p105 p107 p204 p204_si p605-p702 p709 p711 p712 {
replace `x'=0 if `x'==2
}
* Reemplazando "X" por "1"
foreach x of varlist p111_1- p111_6 {
replace `x'="0" if `x'==""
replace `x'="1" if `x'=="X"
destring `x',replace
}

* Reorganizando/creando variables

** Tipo de local:
replace p101=3 if p101==4 | p101==5
rename p101 tipo_local
label define tipo_local 1 "Propio" 2 "Alquilado" 3 "Prestado"
label values tipo_local tipo_local
/*
tab tipo_local,gen(tipo_local_)
rename tipo_local_1 local_propio
rename tipo_local_2 local_alquilado
rename tipo_local_3 local_prestado
order local_propio-local_prestado,after(tipo_local)
*/

** Propiedad de local:
replace p104=5 if p104==3
rename p104 prop_local
label define prop_local 1 "MINEDU" 2 "DRE" 4 "Comunidad" 5 "Otro estatal"
label values prop_local prop_local

/*
tab prop_local,gen(prop_local_)
rename prop_local_1 prop_MINEDU
rename prop_local_2 prop_DRE
rename prop_local_3 prop_comunidad
rename prop_local_4 prop_otroestatal
order prop_local_1-prop_local_4,after(prop_local)
*/

* Local es compartido:
gen local_compartido=1 if p105==0
replace local_compartido=2 if p106==1
replace local_compartido=3 if p106==2
replace local_compartido=4 if (p106==3 | p106==4)
label define local_compartido 1 "No compartido" 2 "DRE" 3 "Entidad pública"  4 "Entidad privada"
label values local_compartido local_compartido
drop p105 p106
/*
replace local_compartido_dre=(p106==1)
replace local_compartido_entpublica=(p106==2)
replace local_compartido_otro=(p106==3 | p106==4)
*/

** Cuenta con certificado de inspección:
rename p107 certificado_inspeccion

** Vía para llegar desde la UGEL
rename p111_1 llegar_viapavimentada
rename p111_2 llegar_viaafirmada
rename p111_3 llegar_trochacarr
rename p111_4 llegar_peatonal
rename p111_5 llegar_fluvial
rename p111_6 llegar_otro

** Cerco perimétrico:
gen cerco=1 if p204==0
replace cerco=2 if p204_si==0
replace cerco=3 if p204_si==1
label define cerco 1 "No tiene" 2 "Parcial" 3 "Total"
label values cerco cerco
drop p204*

** Cantidad de aulas en el local
rename p301_qaula cantidad_aulas

** Tiene biblioteca
gen biblioteca=1 if p605==0
replace biblioteca=2 if p606==0
replace biblioteca=3 if p606==1
drop p605 p606
label define biblioteca 1 "No tiene" 2 "Sí, compartida" 3 "Sí, exclusiva"
label values biblioteca biblioteca

rename p702 local_internet
rename p703 tipo_internet
replace tipo_internet=3 if tipo_internet==4
label define tipo_internet 1 "Cable" 2 "Wifi" 3 "Satelital/otro"
label values tipo_internet tipo_internet
/*
tab tipo_internet,gen(internet_)
rename internet_1 internet_cable
rename internet_2 internet_wifi
rename internet_3 internet_satelital
*/

** Local cuenta con energia 24 horas:
gen energia24horas=p709==1
drop p709 p708

** Abastecimiento de agua:
replace p711=2 if p711==3 | p711==4 
rename p711 tipo_agua
label define tipo_agua  1 "Red pública" 2 "Pilón/caminón/pozo" 5 "Río" 6 "Otro/no tiene"
label values tipo_agua tipo_agua
/*
tab tipo_agua,gen(tipo_agua_)
rename tipo_agua_1 agua_redpubli
rename tipo_agua_2 agua_redpiloncamionpozo
rename tipo_agua_3 agua_rio
rename tipo_agua_4 agua_otronotiene
*/

** Agua las 24 horas:
rename p712 agua_24horas


***** FILTROS APLICADOS *****

** 1) Energia electrica en el local o centro poblado:
keep if energia24horas==1
** 4) Contar con conectividad a Internet en el local o ccpp: 
keep if local_internet==1
** 5) Contar con elementos de seguridad (cerco perimetrico completo)
keep if cerco==3


$temp
save "lineal_trab",replace


**********************************
* Base de datos del local_sec112 *
**********************************

$censo
use codlocal p112_nm p112_tur using "local_sec112.dta",clear

* Conservamos Turno mañana y EBR Primaria, EBR Secundaria, Superior Pedagógica, Superior Tecnológica, CETPRO
keep if p112_tur=="11" & (p112_nm=="B0"| p112_nm=="F0"| p112_nm=="K0"|p112_nm=="T0"|p112_nm=="L0")
tab p112_nm,gen(n_)
drop p112_tur p112_nm
rename n_1 n_primaria
rename n_2 n_secundaria
rename n_3 n_iesp
rename n_4 n_cetpro
rename n_5 n_iest

gen nro_niveles=1
collapse(sum) nro_niveles (max) n_primaria-n_iest,by(codlocal)

$temp
save "sec112_trab_niveles",replace


**********************************
* Base de datos del local_sec206 *
**********************************
$censo
use codlocal p206_1 p206_9 p206_12 using "local_sec206.dta",clear
destring p206_9 p206_12,replace

* Conservar lo portones en buen estado:
keep if p206_12=="01"
drop if p206_9==2

collapse (max) p206_9,by(codlocal)
drop p206_9


** FILTRO APLICADO **
** 5) Contar con elementos de seguridad (cerco perimetrico completo)
$temp
save "sec206_porton_buenestado"

**********************************
* Base de datos del local_sec300 *
**********************************
$censo
use codlocal p300_3 p300_5 using "local_sec300.dta",clear

** FILTRO APLICADO **
** 3) Contar con al menos un aula disponible 
**** pendiente
keep if p300_5=="2"
gen amb_disponibles=1
collapse(sum) amb_disponibles,by(codlocal)
$temp
save "sec300_amb_disponibles"

**********************************
* Base de datos del local_sec700 *
**********************************
$censo
use codlocal orden p700_2 if ((orden==4 | orden==5) & p700_2>=1) using "local_sec700.dta",clear
gen nro_pcs=p700_2 if orden==4
gen nro_laptops=p700_2 if orden==5
collapse (sum) nro_pcs nro_laptops,by(codlocal)
gen nro_equipos_disponibles= nro_pcs+nro_laptops

** FILTRO APLICADO **
** 2) Contar con al menos 10 equipos de cómputo:
keep if nro_equipos_disponibles>=10
$temp
save "sec700_equipos_disponibles"

**************************
**************************

* Merge del padron 2020 con las bases generadas pasos arriba:
$censo20
use cod_mod anexo codlocal cen_edu niv_mod d_niv_mod gestion d_gestion cod_tur d_cod_tur  codgeo dpto prov dist codooii dre_ugel region_edu dareamed region_nat using "padron.dta" if (anexo=="0" & gestion=="1" | gestion=="2"),clear
drop anexo

** a) Anexando base lineal de locales escolares:
$temp
merge m:1 codlocal using "lineal_trab"
keep if _merge==3
drop _merge

** Filtros ya aplicados:
** 1) Energia electrica en el local o centro poblado:
** 4) Contar con conectividad a Internet en el local o ccpp: 
** 5) Contar con elementos de seguridad (cerco perimetrico completo)

*** Conservamos solo un dato por local:
bys codlocal: gen orden_local=_n
keep if orden_local==1

** b) Anexando base de sec112_trab_niveles, que muestra los niveles presentes en el local, 
* la cual conserva Turno mañana y EBR Primaria, EBR Secundaria, Superior Pedagógica, Superior Tecnológica, CETPRO
$temp
merge 1:1 codlocal using "sec112_trab_niveles"
keep if _merge==3
drop _merge orden_local
rename (n_primaria n_secundaria n_iesp n_cetpro n_iest) (local_primaria local_secundaria local_iesp local_cetpro local_iest)
drop niv_mod d_niv_mod cod_tur d_cod_tur


** c) Anexando base de sec206_porton_buenestado, que identifica los locales que tienen porton en buen estado: 
$temp
merge 1:1 codlocal using "sec206_porton_buenestado"
rename p206_9 porton_buenestado
replace porton_buenestado=0 if porton_buenestado==.
drop if _merge==2
drop _merge

** d) Anexando base de , que filtra 3) los locales que al menos tienen un ambiente disponible
$temp
merge 1:1 codlocal using "sec300_amb_disponibles"
keep if _merge==3
drop _merge

** e) Anexando base de sec700_equipos_disponibles, que filtra 2) los locales que tienen al menos 10 equipos disponibles
$temp
merge 1:1 codlocal using "sec700_equipos_disponibles"
keep if _merge==3
drop _merge

codebook cod_mod codlocal
* Obtenemos 417 locales que cumplen con los 5 filtros definidos

* Realizamos algunos cambios de formato antes de guardar la base:
drop cod_mod gestion d_gestion tipo_local prop_local llegar_fluvial llegar_otro local_compartido cerco energia24horas
foreach x in dpto prov dist region_nat{
replace `x'=proper(`x')
}

* Creando Lima Metropolitana:
replace dpto="Lima Metrop." if dpto=="Lima" & prov=="Lima"
replace dpto="Lima Región" if dpto=="Lima" & prov!="Lima"

$temp
save "local_paratrabajar.dta",replace
export excel using "local_paratrabajar.xlsx",firstrow(variables) replace

*********************************************************
*********************************************************
*********************************************************

********************************************************
* Analisis geografico y de entorno de los 417 locales **
********************************************************

/*
* Primero guardaremos la lista de distritos que cuentan con IESP/IEST (K0/T0)
$censo20
use "padron.dta" if niv_mod=="K0" | niv_mod=="T0",clear
gen nro_IESP=(niv_mod=="K0")
gen nro_IEST=(niv_mod=="T0")
rename codgeo ubigeo
collapse (sum) nro*,by(ubigeo)
$temp
save "distritos_iesp_iest.dta",replace

* Ahora, la lista de distritos con universidades:
global uni cd "D:\Trabajo\Consultoria\USE_MINEDU\Trabajos\BD\Estudiantes IESP"
$uni
use codigo_modular universidad codigo_ubigeo using "SIRIES_postulantes_14_03_21_vf"
gen x=1
collapse (sum) x,by(codigo_modular universidad codigo_ubigeo)
drop x
gen nro_locales_univ=1
collapse (sum) nro_locales_univ,by(codigo_ubigeo)
rename codigo_ubigeo ubigeo
gen str6 ubigeo2 = string(ubigeo,"%06.0f")
drop ubigeo
rename ubigeo2 ubigeo
order ubigeo
$temp
save "distritos_univ.dta",replace
*/

* Abrimos la base de los 417 locales:
$temp
use "local_paratrabajar.dta",clear
rename codgeo ubigeo
$dist
merge m:1 ubigeo using "prebase_final"
keep if _merge==3
drop _merge departamento- poblacion_2019_prov dev_pc_act19- perc_urbano_censo montopc_acts- fallecidos_relativo

/*
preserve
gen nro_centros=1
collapse (sum) nro_centros,by(ubigeo dpto prov dist)
$result
export excel using "ubigeo_nrocentros.xlsx",firstrow(variables) replace
restore
*/

* Pegamos información adicional de programas sociales, IESP/IEST y Universidades presentes
global lista cd "D:\Trabajo\Consultoria\USE_MINEDU\Set-Nov21\Oct-Nov-CentrosDigitales-Cesar\Listados"
$lista
merge m:1 ubigeo using "listado_ppss_distrito2021",keepusing(cunamas_diurno cunamas_acomp juntos_hogares foncodes_usuarios p65_usuarios nro_tambos)
keep if _merge==3
drop _merge

$temp
merge m:1 ubigeo using "distritos_iesp_iest"
drop if _merge==2
drop _merge
merge m:1 ubigeo using "distritos_univ"
drop if _merge==2
drop _merge

foreach x of varlist cunamas_diurno- nro_locales_univ{
replace `x'=0 if `x'==.
}

* Generando indicadores de los criterios mencionados en el documento *

* OPORTUNIDADES:

** C1: ciudades intermerdias o pequeñas conectadas según categoría PCM:
gen C1_PCM=(CATEGORIA_PCM==3 | CATEGORIA_PCM==4)
label var C1_PCM "C1:ciudadades intermedias/pequeñas conectadas-PCM"

** C2: Distritos con presencia de programas sociales/Tambos (mas de 100 usuarios P65, o de hogares Juntos o al menos un tambo)
gen C2_PPSS=(juntos_hogares>=100 | p65_usuarios>=100 | nro_tambos>=1)
label var C2_PPSS "C2: Presencia de programas sociales y/o Tambos"

** C3: Presencia de centros de educación superior (IEST/IESP/Universidades) - al menos uno
gen C3_edusup=(nro_IESP>=1 | nro_IEST>=1 | nro_locales_univ>=1)
label var C3_edusup "C3: al menos un centro de educación superior"

* RETOS: 

** C4: las 5 regiones (para cada caso) con tasas más bajas de uso de PCs o Laptops por parte de adultos y estudiantes EBR:
gen C4_bajoaccesoTIC=(dpto=="Cajamarca" | dpto=="Amazonas" | dpto=="Huancavelica" | dpto=="Loreto" | dpto=="Huánuco" | dpto=="Apurimac" | dpto=="Junin")
label var C4_bajoaccesoTIC "C4: Region con bajo uso de TIC"

** C5: Las 5 regiones con tasas más altas de autoempleo/emprendimiento
gen C5_autoempleo=(dpto=="Ayacucho" | dpto=="Amazonas" | dpto=="Cajamarca" | dpto=="Loreto" | dpto=="Tumbes")
label var C5_autoempleo "C5: Region con alta tasa de autoempleo"

** C6: Las 5 regiones con porcentajes más altos de NINI
gen C6_nini=(dpto=="Lima Metrop." | dpto=="Tacna" | dpto=="Arequipa" | dpto=="Loreto" | dpto=="Pasco")
label var C6_nini "C6: Region con alta tasa de NINI"

egen nro_criterios=rowtotal(C1-C6)

* N° de IIEEs que cumplen al menos un criterio de cada tipo:

** Cumplen criterios de oportunidad:




$temp
save "local_trabajado.dta",replace
keep codlocal- dist C1_PCM- nro_criterios dareamed
export excel using "local_trabajado.xlsx",firstrow(variables) replace










