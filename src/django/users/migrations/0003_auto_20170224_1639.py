# -*- coding: utf-8 -*-
# Generated by Django 1.10.3 on 2017-02-24 16:39
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0002_auto_20170221_1653'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='organization',
            name='neighborhood',
        ),
        migrations.AlterField(
            model_name='organization',
            name='org_type',
            field=models.CharField(choices=[('ADMIN', 'PFB Administrator Organization'), ('SUBSCRIBER', 'Subscriber')], max_length=10),
        ),
    ]
