from django.contrib.auth.hashers import make_password
from django.contrib.auth.management import create_permissions
from django.core.management import call_command
from django.core.serializers import base
from django.utils import timezone
from rest_framework.authtoken.models import Token


def load_migration_fixture(apps, schema_editor, fixture, app_label):
    """Load a fixture during a migration.

    This function loads a fixture during a migration using the correct app state
    at the time of the migration.

    :param apps: Apps at the state of the migration.
    :param schema_editor: The schema at the time of the migration.
    :param fixture: A path to the fixture to be loaded.
    :param app_label: The app label the fixture should be loaded into.
    :return: None
    """
    original_serializer_get_model = base.serializers.get_model

    def get_model_at_migration(model_identifier):
        try:
            return apps.get_model(model_identifier)
        except (LookupError, TypeError):
            raise base.DeserializationError(
                f"Invalid model identifier: '{model_identifier}'"
            )

    base.serializers.get_model = get_model_at_migration

    try:
        call_command("loaddata", fixture, app_label=app_label)
    finally:
        base.serializers.get_model = original_serializer_get_model


def make_new_user(apps, schema_editor, username, email, permission_codenames):
    User = apps.get_model(
        "auth",
        "User",
    )
    UserProfile = apps.get_model("users", "UserProfile")
    Permission = apps.get_model("auth", "Permission")
    new_user = User.objects.create(
        username=username,
        email=email,
        password=make_password(None),  # Unusable password
        date_joined=timezone.now(),
    )
    UserProfile.objects.create(
        user=new_user,
        email_confirmed=True,
    )

    # Give the user permissions
    # https://stackoverflow.com/a/41564061/64911
    for app_config in apps.get_app_configs():
        app_config.models_module = True
        create_permissions(app_config, verbosity=0)
        app_config.models_module = None

    for codename in permission_codenames:
        p = Permission.objects.get(codename=codename)
        new_user.user_permissions.add(p)

    Token.objects.get_or_create(user_id=new_user.id)
