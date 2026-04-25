"""Script to create test database."""
import asyncio
import asyncpg


async def create_test_database():
    """Create the test database if it doesn't exist."""
    try:
        # Connect to default postgres database
        conn = await asyncpg.connect(
            host='localhost',
            port=5432,
            user='postgres',
            password='1234',
            database='postgres'
        )
        
        # Check if test database exists
        exists = await conn.fetchval(
            "SELECT 1 FROM pg_database WHERE datname = 'restaurant_test_db'"
        )
        
        if not exists:
            # Create test database
            await conn.execute('CREATE DATABASE restaurant_test_db')
            print("✓ Test database 'restaurant_test_db' created successfully")
        else:
            print("✓ Test database 'restaurant_test_db' already exists")
        
        await conn.close()
        return True
        
    except Exception as e:
        print(f"✗ Error creating test database: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.run(create_test_database())
    exit(0 if success else 1)
