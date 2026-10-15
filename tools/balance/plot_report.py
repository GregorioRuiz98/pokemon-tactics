"""Plot saved audit results; install requirements-report.txt separately from the game."""
import json
import pathlib
import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'docs/reports/balance-2026-10-15')
data = json.loads((root / 'summary.json').read_text(encoding='utf-8'))
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False})
policies = data['policies']
labels = {'reference':'Seis · curar inmediatamente', 'trio':'Tres · conservar curación', 'six':'Seis · conservar curación',
          'evolution':'Seis · invertir en evolución', 'leftovers':'Seis · invertir en Restos',
          'vest':'Seis · invertir en Chaleco', 'four':'Cuatro · conservar curación', 'trio-evolution':'Tres · invertir en evolución', 'trio-leftovers':'Tres · invertir en Restos', 'boots':'Seis · invertir en Botas'}
fig, ax = plt.subplots(figsize=(11, 8.4), layout='constrained')
y = np.arange(len(policies))
for name, offset, color, label in [('birds', -.13, '#21618c', 'Tres aves'), ('psychic', .13, '#a04d38', 'Mew y Mewtwo')]:
    values = [p['finals'][name]['rate'] * 100 for p in policies]
    bounds = [p['finals'][name]['ci'] for p in policies]
    errors = np.maximum(0, np.array([[value-low*100, high*100-value] for value,(low,high) in zip(values,bounds)]).T)
    ax.errorbar(values, y+offset, xerr=errors, fmt='o', color=color, capsize=3, label=label)
    for x, row in zip(values,y+offset):
        ax.annotate(f'{x:.1f} %', (x,row), xytext=(5,7 if name=='birds' else -13), textcoords='offset points', fontsize=9, color=color)
ax.set_yticks(y, [labels[p['id']] for p in policies]); ax.invert_yaxis(); ax.set_xlim(-1, 100)
ax.set_xlabel('Victorias observadas por cada 100 semillas (incluye no llegar al final)')
ax.set_title('Equipo y gasto: resultados de la campaña actual', loc='left', fontweight='bold', pad=30)
ax.text(0,1.025,f"IA contra IA · {data['metadata']['seeds']} semillas por política · IC Wilson 95 % · límite 100 rondas por combate", transform=ax.transAxes, fontsize=9)
ax.grid(axis='x',alpha=.2); ax.set_axisbelow(True); ax.legend(loc='lower right')
fig.savefig(root/'victorias-estrategias.png', dpi=180); fig.savefig(root/'victorias-estrategias.svg'); plt.close(fig)

fig, axes = plt.subplots(1,2,figsize=(12,5.4),layout='constrained')
floor_names=['Roca','Agua','Eléctrico','Planta','Veneno','Psíquico','Fuego','Tierra']
floor_data=data['floors']; x=np.arange(8)
axes[0].barh(x,[f['deathsPerFight'] for f in floor_data],color='#427c6d')
axes[0].set_yticks(x,floor_names);axes[0].invert_yaxis();axes[0].set_xlabel('Bajas aliadas por combate iniciado')
for i,f in enumerate(floor_data): axes[0].text(f['deathsPerFight']+.025,i,f"{f['deathsPerFight']:.2f} · n={f['n']}",va='center',fontsize=9)
axes[0].set_xlim(0,max(f['deathsPerFight'] for f in floor_data)*1.45);axes[0].set_title('El desgaste cambia entre zonas',loc='left',fontweight='bold')
base=next(p for p in policies if p['id']=='six')
reached=base['reached'];bird=base['finals']['birds'];psy=base['finals']['psychic']
axes[1].bar(['Alcanzan el final','Vencen aves','Vencen psíquicos'],[reached,bird['wins'],psy['wins']],color=['#7d8870','#21618c','#a04d38'])
axes[1].set_ylim(0,data['metadata']['seeds']*1.1);axes[1].set_ylabel('Semillas de la política «Seis · conservar curación»')
for i,value in enumerate([reached,bird['wins'],psy['wins']]):axes[1].text(i,value+3,str(value),ha='center')
axes[1].set_title('Llegar y ganar son dificultades distintas',loc='left',fontweight='bold')
axes[1].tick_params(axis='x',labelsize=9)
fig.suptitle('Misma política y mismas semillas; cada final parte del mismo equipo',fontsize=10)
fig.savefig(root/'desgaste-y-finales.png',dpi=180);plt.close(fig)
print('Two report figures and one vector copy generated with Matplotlib '+matplotlib.__version__)
