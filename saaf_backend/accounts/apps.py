# accounts/apps.py
import threading
from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'accounts'

    def ready(self):
        """
        Called once when Django has finished loading all models.
        We kick off LightGCN training in a background thread so startup
        is non-blocking. The recommendations endpoint uses a cold-start
        fallback until the model finishes training.
        """
        import os

        # In development mode Django starts two processes (reloader + worker).
        # RUN_MAIN='true' is set only in the actual worker, so we skip
        # training in the reloader process to avoid training twice.
        # In production (gunicorn) RUN_MAIN is never set, so we always train.
        if os.environ.get('RUN_MAIN') == 'false':
            return

        def _train():
            try:
                from .recommendations import train_recommender
                train_recommender()
            except Exception as exc:          # pragma: no cover
                import logging
                logging.getLogger(__name__).error(
                    f"[Recommender] Background training failed: {exc}"
                )

        thread = threading.Thread(target=_train, daemon=True, name="LightGCN-trainer")
        thread.start()
