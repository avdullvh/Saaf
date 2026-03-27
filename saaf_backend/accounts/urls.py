# accounts/urls.py  — /api/auth/
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Accept both with/without trailing slash to avoid POST redirect issues.
    path('register',         views.register,      name='auth-register-noslash'),
    path('register/',        views.register,      name='auth-register'),
    path('login',            views.login,          name='auth-login-noslash'),
    path('login/',           views.login,          name='auth-login'),
    path('token/refresh/',   TokenRefreshView.as_view(), name='token-refresh'),
]
