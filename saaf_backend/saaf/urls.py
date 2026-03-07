"""saaf/urls.py — Root URL configuration"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/',            admin.site.urls),
    path('api/auth/',         include('accounts.urls')),
    path('api/posts/',        include('feed.urls')),
    path('api/profile/',      include('accounts.profile_urls')),
    path('api/',              include('classify.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
