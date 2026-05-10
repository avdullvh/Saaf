# accounts/serializers.py
import re

from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User


class UserSerializer(serializers.ModelSerializer):
    post_count      = serializers.IntegerField(read_only=True)
    followers_count = serializers.IntegerField(read_only=True)
    following_count = serializers.IntegerField(read_only=True)
    avatar_url      = serializers.SerializerMethodField()
    is_following    = serializers.SerializerMethodField()

    class Meta:
        model  = User
        fields = [
            'id', 'email', 'full_name', 'bio', 'avatar_url',
            'post_count', 'followers_count', 'following_count', 'is_following',
        ]

    def get_avatar_url(self, obj):
        request = self.context.get('request')
        if obj.avatar and request:
            return request.build_absolute_uri(obj.avatar.url)
        if obj.avatar:
            return f'http://127.0.0.1:8000{obj.avatar.url}'
        return None

    def get_is_following(self, obj):
        """Returns True if the authenticated request user follows this profile."""
        request = self.context.get('request')
        if request is None or not request.user.is_authenticated:
            return False
        if request.user.pk == obj.pk:
            return False  # can't follow yourself
        return obj.followers.filter(follower=request.user).exists()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model  = User
        fields = ['email', 'full_name', 'password']

    def validate_password(self, value):
        if not re.search(r'[A-Za-z]', value) or not re.search(r'\d', value):
            raise serializers.ValidationError(
                'Password must be at least 6 characters and contain letters and numbers.'
            )
        return value

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)


def get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access':  str(refresh.access_token),
    }
