# accounts/profile_urls.py  — /api/profile/
from django.urls import path
from . import views

urlpatterns = [
    path('<int:user_id>/',           views.profile,        name='profile-detail'),
    path('<int:user_id>/posts/',     views.profile_posts,  name='profile-posts'),
    path('<int:user_id>/follow/',    views.follow_toggle,  name='profile-follow'),
    path('<int:user_id>/followers/', views.followers_list, name='profile-followers'),
    path('<int:user_id>/following/', views.following_list, name='profile-following'),
    path('recommendations/',         views.recommendations,       name='profile-recommendations'),
    path('recommendations/retrain/', views.retrain_recommender,   name='profile-recommendations-retrain'),
]
