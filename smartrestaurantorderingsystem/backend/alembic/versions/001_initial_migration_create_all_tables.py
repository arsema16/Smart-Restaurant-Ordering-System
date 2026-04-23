"""Initial migration: create all tables with indexes and constraints

Revision ID: 001
Revises: 
Create Date: 2026-04-23

This migration creates all tables for the Smart Restaurant Ordering System:
- table_sessions: QR-based session management
- menu_items: Restaurant menu catalog
- cart_items: User shopping carts
- orders: Confirmed orders
- order_items: Order line items
- user_profiles: User preference tracking
- staff_users: Staff authentication

Requirements: 9.4, 10.1
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create all tables with indexes and constraints."""
    
    # Create table_sessions table
    op.create_table(
        'table_sessions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('table_identifier', sa.String(length=64), nullable=False),
        sa.Column('session_token', sa.String(length=128), nullable=False),
        sa.Column('persistent_user_id', sa.String(length=128), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('last_active_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_table_sessions')),
        sa.UniqueConstraint('session_token', name=op.f('uq_table_sessions_session_token'))
    )
    op.create_index(op.f('ix_table_sessions_session_token'), 'table_sessions', ['session_token'], unique=False)
    op.create_index(op.f('ix_table_sessions_table_identifier'), 'table_sessions', ['table_identifier'], unique=False)
    
    # Create menu_items table
    op.create_table(
        'menu_items',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('category', sa.String(length=128), nullable=False),
        sa.Column('price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('prep_time_minutes', sa.Integer(), nullable=False),
        sa.Column('is_available', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.CheckConstraint('price > 0', name='check_price_positive'),
        sa.CheckConstraint('prep_time_minutes > 0', name='check_prep_time_positive'),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_menu_items'))
    )
    
    # Create user_profiles table
    op.create_table(
        'user_profiles',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('persistent_user_id', sa.String(length=128), nullable=False),
        sa.Column('most_ordered_items', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'[]'::jsonb")),
        sa.Column('recently_ordered_items', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'[]'::jsonb")),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_user_profiles')),
        sa.UniqueConstraint('persistent_user_id', name=op.f('uq_user_profiles_persistent_user_id'))
    )
    
    # Create staff_users table
    op.create_table(
        'staff_users',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('username', sa.String(length=128), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('role', sa.String(length=32), nullable=False, server_default=sa.text("'staff'")),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_staff_users')),
        sa.UniqueConstraint('username', name=op.f('uq_staff_users_username'))
    )
    
    # Create cart_items table (depends on table_sessions and menu_items)
    op.create_table(
        'cart_items',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('menu_item_id', sa.Integer(), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('added_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.CheckConstraint('quantity > 0', name='check_quantity_positive'),
        sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], name=op.f('fk_cart_items_menu_item_id_menu_items')),
        sa.ForeignKeyConstraint(['session_id'], ['table_sessions.id'], name=op.f('fk_cart_items_session_id_table_sessions'), ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_cart_items')),
        sa.UniqueConstraint('session_id', 'menu_item_id', name='uq_session_menu_item')
    )
    
    # Create orders table (depends on table_sessions)
    op.create_table(
        'orders',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_number', sa.String(length=32), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default=sa.text("'Received'")),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.CheckConstraint("status IN ('Received', 'Cooking', 'Ready', 'Delivered')", name='check_status_valid'),
        sa.ForeignKeyConstraint(['session_id'], ['table_sessions.id'], name=op.f('fk_orders_session_id_table_sessions')),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_orders')),
        sa.UniqueConstraint('order_number', name=op.f('uq_orders_order_number'))
    )
    op.create_index(op.f('ix_orders_session_id'), 'orders', ['session_id'], unique=False)
    op.create_index(op.f('ix_orders_status'), 'orders', ['status'], unique=False)
    
    # Create order_items table (depends on orders and menu_items)
    op.create_table(
        'order_items',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('menu_item_id', sa.Integer(), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('unit_price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.CheckConstraint('quantity > 0', name='check_order_item_quantity_positive'),
        sa.CheckConstraint('unit_price > 0', name='check_unit_price_positive'),
        sa.ForeignKeyConstraint(['menu_item_id'], ['menu_items.id'], name=op.f('fk_order_items_menu_item_id_menu_items')),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], name=op.f('fk_order_items_order_id_orders'), ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_order_items'))
    )


def downgrade() -> None:
    """Drop all tables in reverse order."""
    
    # Drop tables in reverse order of creation (respecting foreign key dependencies)
    op.drop_table('order_items')
    op.drop_index(op.f('ix_orders_status'), table_name='orders')
    op.drop_index(op.f('ix_orders_session_id'), table_name='orders')
    op.drop_table('orders')
    op.drop_table('cart_items')
    op.drop_table('staff_users')
    op.drop_table('user_profiles')
    op.drop_table('menu_items')
    op.drop_index(op.f('ix_table_sessions_table_identifier'), table_name='table_sessions')
    op.drop_index(op.f('ix_table_sessions_session_token'), table_name='table_sessions')
    op.drop_table('table_sessions')
