# feed/serializers.py
from rest_framework import serializers
from .models import Post, Comment


class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.full_name', read_only=True)
    author_id   = serializers.IntegerField(source='author.id', read_only=True)

    class Meta:
        model  = Comment
        fields = ['id', 'author_id', 'author_name', 'body', 'created_at']
        read_only_fields = ['id', 'author_id', 'author_name', 'created_at']


class PostSerializer(serializers.ModelSerializer):
    author_name     = serializers.CharField(source='author.full_name', read_only=True)
    author_id       = serializers.IntegerField(source='author.id', read_only=True)
    author_avatar_url = serializers.SerializerMethodField()
    likes_count     = serializers.IntegerField(read_only=True)
    comments_count  = serializers.IntegerField(read_only=True)
    liked_by_me     = serializers.SerializerMethodField()
    classification  = serializers.SerializerMethodField()
    image_url       = serializers.SerializerMethodField()

    class Meta:
        model  = Post
        fields = [
            'id', 'author_id', 'author_name', 'author_avatar_url',
            'caption', 'image_url', 'classification',
            'likes_count', 'liked_by_me',
            'comments_count', 'created_at',
        ]
        read_only_fields = ['id', 'author_id', 'author_name', 'author_avatar_url',
                            'created_at', 'likes_count', 'liked_by_me',
                            'comments_count', 'image_url']

    def get_liked_by_me(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def get_author_avatar_url(self, obj):
        request = self.context.get('request')
        if obj.author.avatar:
            if request:
                return request.build_absolute_uri(obj.author.avatar.url)
            return f'http://127.0.0.1:8000{obj.author.avatar.url}'
        return None

    def get_classification(self, obj):
        return {
            'predicted_type':   obj.predicted_type,
            'confidence_score': obj.confidence_score,
        }

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image.url)
            return f'http://127.0.0.1:8000{obj.image.url}'
        return None


class CreatePostSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Post
        fields = ['caption', 'predicted_type', 'confidence_score', 'image']
        extra_kwargs = {'image': {'required': False}}

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)
