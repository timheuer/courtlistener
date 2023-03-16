# Generated by Django 3.2.18 on 2023-03-16 02:46

from django.db import migrations
import pgtrigger.compiler
import pgtrigger.migrations


class Migration(migrations.Migration):

    dependencies = [
        ('donate', '0003_add_event_tables_and_triggers'),
    ]

    operations = [
        pgtrigger.migrations.RemoveTrigger(
            model_name='donation',
            name='snapshot_insert',
        ),
        pgtrigger.migrations.RemoveTrigger(
            model_name='donation',
            name='snapshot_update',
        ),
        pgtrigger.migrations.RemoveTrigger(
            model_name='monthlydonation',
            name='snapshot_insert',
        ),
        pgtrigger.migrations.RemoveTrigger(
            model_name='monthlydonation',
            name='snapshot_update',
        ),
        pgtrigger.migrations.AddTrigger(
            model_name='donation',
            trigger=pgtrigger.compiler.Trigger(name='custom_snapshot_insert', sql=pgtrigger.compiler.UpsertTriggerSql(func='INSERT INTO "donate_donationevent" ("amount", "clearing_date", "date_created", "date_modified", "donor_id", "id", "payment_id", "payment_provider", "pgh_context_id", "pgh_created_at", "pgh_label", "pgh_obj_id", "referrer", "send_annual_reminder", "status", "transaction_id") VALUES (NEW."amount", NEW."clearing_date", NEW."date_created", NEW."date_modified", NEW."donor_id", NEW."id", NEW."payment_id", NEW."payment_provider", _pgh_attach_context(), NOW(), \'custom_snapshot\', NEW."id", NEW."referrer", NEW."send_annual_reminder", NEW."status", NEW."transaction_id"); RETURN NULL;', hash='664496d2d546bc6786bca92e0f769e0ca57b7330', operation='INSERT', pgid='pgtrigger_custom_snapshot_insert_4449d', table='donate_donation', when='AFTER')),
        ),
        pgtrigger.migrations.AddTrigger(
            model_name='donation',
            trigger=pgtrigger.compiler.Trigger(name='custom_snapshot_update', sql=pgtrigger.compiler.UpsertTriggerSql(condition='WHEN (OLD.* IS DISTINCT FROM NEW.*)', func='INSERT INTO "donate_donationevent" ("amount", "clearing_date", "date_created", "date_modified", "donor_id", "id", "payment_id", "payment_provider", "pgh_context_id", "pgh_created_at", "pgh_label", "pgh_obj_id", "referrer", "send_annual_reminder", "status", "transaction_id") VALUES (OLD."amount", OLD."clearing_date", OLD."date_created", OLD."date_modified", OLD."donor_id", OLD."id", OLD."payment_id", OLD."payment_provider", _pgh_attach_context(), NOW(), \'custom_snapshot\', OLD."id", OLD."referrer", OLD."send_annual_reminder", OLD."status", OLD."transaction_id"); RETURN NULL;', hash='ccf128f8ca2b7fa8188cf0afce15f91f022c1a37', operation='UPDATE', pgid='pgtrigger_custom_snapshot_update_5933b', table='donate_donation', when='AFTER')),
        ),
        pgtrigger.migrations.AddTrigger(
            model_name='monthlydonation',
            trigger=pgtrigger.compiler.Trigger(name='custom_snapshot_insert', sql=pgtrigger.compiler.UpsertTriggerSql(func='INSERT INTO "donate_monthlydonationevent" ("date_created", "date_modified", "donor_id", "enabled", "failure_count", "id", "monthly_donation_amount", "monthly_donation_day", "payment_provider", "pgh_context_id", "pgh_created_at", "pgh_label", "pgh_obj_id", "stripe_customer_id") VALUES (NEW."date_created", NEW."date_modified", NEW."donor_id", NEW."enabled", NEW."failure_count", NEW."id", NEW."monthly_donation_amount", NEW."monthly_donation_day", NEW."payment_provider", _pgh_attach_context(), NOW(), \'custom_snapshot\', NEW."id", NEW."stripe_customer_id"); RETURN NULL;', hash='16616daaa4fe294d4a20b78dda3d9ceb285e2948', operation='INSERT', pgid='pgtrigger_custom_snapshot_insert_60280', table='donate_monthlydonation', when='AFTER')),
        ),
        pgtrigger.migrations.AddTrigger(
            model_name='monthlydonation',
            trigger=pgtrigger.compiler.Trigger(name='custom_snapshot_update', sql=pgtrigger.compiler.UpsertTriggerSql(condition='WHEN (OLD.* IS DISTINCT FROM NEW.*)', func='INSERT INTO "donate_monthlydonationevent" ("date_created", "date_modified", "donor_id", "enabled", "failure_count", "id", "monthly_donation_amount", "monthly_donation_day", "payment_provider", "pgh_context_id", "pgh_created_at", "pgh_label", "pgh_obj_id", "stripe_customer_id") VALUES (OLD."date_created", OLD."date_modified", OLD."donor_id", OLD."enabled", OLD."failure_count", OLD."id", OLD."monthly_donation_amount", OLD."monthly_donation_day", OLD."payment_provider", _pgh_attach_context(), NOW(), \'custom_snapshot\', OLD."id", OLD."stripe_customer_id"); RETURN NULL;', hash='8e5f76fd507b4af5a13a0fe2896c05646a9e3569', operation='UPDATE', pgid='pgtrigger_custom_snapshot_update_997e1', table='donate_monthlydonation', when='AFTER')),
        ),
    ]
