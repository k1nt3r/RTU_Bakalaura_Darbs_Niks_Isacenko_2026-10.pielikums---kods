# RTU_Bakalaura_Darbs_Niks_Isa-enko_2026-10.pielikums---kods
Programmas kodi, kas izstrādāts bakalaura darba ietvaros


# Vehicle Fault Prediction System

Šis repozitorijs ir izveidots bakalaura darba praktiskajai daļai.

Darba tēma: **Mākslīgo neironu tīklu pielietošana transportlīdzekļu tehniskā stāvokļa analīzei un prognozēšanai, izmantojot borta diagnostikas sistēmas datus**.

Repozitorijā atrodas MATLAB kodi, kas tika izmantoti divlīmeņu transportlīdzekļa diagnostikas sistēmas izstrādei, sintētiskās datu kopas ģenerēšanai un datu analīzei.

## Faili

- `vehicle_fault_system.m` - galvenā diagnostikas sistēma. Tajā tiek ģenerēta sintētiska datu kopa, apmācīts MLP neironu tīkls un veikta kļūmju noteikšana.
- `kit_data_analysis.m` - KIT OBD-II datu kopas analīze un vizualizāciju izveide.
- `figures/` - darba attēli un grafiki.
- `README.md` - īss repozitorija apraksts.

## Datu kopas

Datu kopas netiek pievienotas šim repozitorijam, jo tās ir lejupielādējamas no ārējiem avotiem. Repozitorijā ir norādītas tikai saites uz datu avotiem.

Izmantotās datu kopas:

1. **Automotive OBD-II Dataset**

   Šī datu kopa tika izmantota reālu OBD-II parametru analīzei un sliekšņu pārbaudei.

   Lejupielādes saite: https://radar.kit.edu/radar/en/dataset/bCtGxdTklQlfQcAq

2. **Kaggle Machine Predictive Maintenance Classification Dataset**

   Šī datu kopa tika izmantota kā viens no galvenajiem avotiem kļūmju tipu un prognozējošās apkopes loģikas izpratnei. No tās tika ņemta ideja par iespējamiem atteices veidiem un to saistību ar iekārtas darbības parametriem. Darbā šī pieeja tika pielāgota transportlīdzekļu diagnostikas uzdevumam, apvienojot predictive maintenance principu ar SAE J1979 balstītiem OBD-II parametru sliekšņiem.

   Lejupielādes saite: https://www.kaggle.com/datasets/shivamb/machine-predictive-maintenance-classification
