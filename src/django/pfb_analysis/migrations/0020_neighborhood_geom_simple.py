# -*- coding: utf-8 -*-
# Generated by Django 1.10.3 on 2017-04-26 14:58
from __future__ import unicode_literals

import django.contrib.gis.db.models.fields
from django.db import migrations

from pfb_analysis.models import simplify_geom


def add_neighborhood_simplified_geoms(apps, schema_editor):
    Neighborhood = apps.get_model("pfb_analysis", "Neighborhood")
    for n in Neighborhood.objects.all():
        n.geom_simple = simplify_geom(n.geom)
        n.save()


class Migration(migrations.Migration):

    dependencies = [
        ('pfb_analysis', '0019_auto_20170421_1746'),
    ]

    operations = [
        migrations.AddField(
            model_name='neighborhood',
            name='geom_simple',
            field=django.contrib.gis.db.models.fields.MultiPolygonField(blank=True,
                                                                        null=True,
                                                                        srid=4326),
        ),
        migrations.RunPython(add_neighborhood_simplified_geoms,
                             reverse_code=migrations.RunPython.noop)
    ]
