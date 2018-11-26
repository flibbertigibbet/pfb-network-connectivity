# -*- coding: utf-8 -*-
# Generated by Django 1.11.13 on 2018-11-26 19:09
from __future__ import unicode_literals

from django.conf import settings
import django.contrib.gis.db.models.fields
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('pfb_analysis', '0030_auto_20180419_1342'),
    ]

    operations = [
        migrations.CreateModel(
            name='CensusBlocksResults',
            fields=[
                ('uuid', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('geom', django.contrib.gis.db.models.fields.MultiPolygonField(blank=True, null=True, srid=4326)),
                ('overall_score', models.FloatField(blank=True, null=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='pfb_analysis_censusblocksresults_related+', to=settings.AUTH_USER_MODEL)),
                ('job', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='census_block_results', to='pfb_analysis.AnalysisJob')),
                ('modified_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='pfb_analysis_censusblocksresults_related+', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.CreateModel(
            name='NeighborhoodWaysResults',
            fields=[
                ('uuid', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('modified_at', models.DateTimeField(auto_now=True)),
                ('geom', django.contrib.gis.db.models.fields.LineStringField(blank=True, null=True, srid=4326)),
                ('tf_seg_str', models.BooleanField(default=False)),
                ('ft_seg_str', models.BooleanField(default=False)),
                ('xwalk', models.BooleanField(default=False)),
                ('ft_bike_in', models.CharField(blank=True, max_length=20, null=True)),
                ('tf_bike_in', models.CharField(blank=True, max_length=20, null=True)),
                ('functional', models.CharField(blank=True, max_length=20, null=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='pfb_analysis_neighborhoodwaysresults_related+', to=settings.AUTH_USER_MODEL)),
                ('job', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='neighborhood_way_results', to='pfb_analysis.AnalysisJob')),
                ('modified_by', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='pfb_analysis_neighborhoodwaysresults_related+', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'abstract': False,
            },
        ),
    ]
