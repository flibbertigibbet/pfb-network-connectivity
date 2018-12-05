# -*- coding: utf-8 -*-
# Generated by Django 1.11.13 on 2018-12-05 16:30
from __future__ import unicode_literals

from django.db import migrations
import django_countries.fields


class Migration(migrations.Migration):

    dependencies = [
        ('pfb_analysis', '0031_censusblocksresults_neighborhoodwaysresults'),
    ]

    operations = [
        migrations.AddField(
            model_name='neighborhood',
            name='country',
            field=django_countries.fields.CountryField(default='US', help_text='The country of the uploaded neighborhood', max_length=2),
            preserve_default=False,
        ),
    ]
