"""saaf/urls.py — Root URL configuration"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include
from django.views.generic.base import RedirectView

urlpatterns = [
    path('',                  lambda request: JsonResponse({"status": "ok", "message": "Saaf backend is running"})),
    path('admin/',            admin.site.urls),
    path('api/auth',          RedirectView.as_view(url='/api/auth/', permanent=False)),
    path('api/auth/',         include('accounts.urls')),
    path('api/posts',         RedirectView.as_view(url='/api/posts/', permanent=False)),
    path('api/posts/',        include('feed.urls')),
    path('api/profile',       RedirectView.as_view(url='/api/profile/', permanent=False)),
    path('api/profile/',      include('accounts.profile_urls')),
    path('api',               RedirectView.as_view(url='/api/', permanent=False)),
    path('api/',              include('classify.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
