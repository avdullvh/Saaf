# accounts/profile_urls.py  — /api/profile/
from django.urls import path
from . import views

urlpatterns = [
    path('<int:user_id>/',       views.profile,       name='profile-detail'),
    path('<int:user_id>/posts/', views.profile_posts,  name='profile-posts'),
]
