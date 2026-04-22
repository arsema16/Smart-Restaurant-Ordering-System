"""Example property-based tests using Hypothesis."""
import pytest
from hypothesis import given, strategies as st, settings, example


@pytest.mark.property
@given(st.integers(), st.integers())
@settings(max_examples=200)
def test_addition_commutative(a: int, b: int):
    """Property: Addition is commutative.
    
    For any two integers a and b, a + b should equal b + a.
    """
    assert a + b == b + a


@pytest.mark.property
@given(st.lists(st.integers(), min_size=0, max_size=100))
@settings(max_examples=200)
def test_list_length_invariant(items: list[int]):
    """Property: List length equals number of items.
    
    For any list, the length should equal the count of items.
    """
    assert len(items) == sum(1 for _ in items)


@pytest.mark.property
@given(st.text(min_size=1, max_size=50))
@settings(max_examples=200)
@example("edge case")  # Add specific examples to test
@example("")  # This will fail min_size constraint, demonstrating @example
def test_string_round_trip(text: str):
    """Property: String encoding/decoding round-trip.
    
    For any string, encoding to bytes and decoding back should
    produce the original string.
    """
    encoded = text.encode('utf-8')
    decoded = encoded.decode('utf-8')
    assert decoded == text


# Example of a property test that would be used in the actual system
# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness
@pytest.mark.property
@given(st.integers(min_value=1, max_value=1000))
@settings(max_examples=200)
def test_session_token_uniqueness_example(n: int):
    """Property: Session tokens are unique.
    
    For any number of session token generations, all tokens should be unique.
    This is a simplified example - the actual implementation will test
    the real session token generation function.
    """
    # Placeholder for actual session token generation
    # from app.services.session_service import generate_session_token
    # tokens = [generate_session_token() for _ in range(n)]
    # assert len(tokens) == len(set(tokens))
    
    # Simplified example using random strings
    import secrets
    tokens = [secrets.token_urlsafe(32) for _ in range(n)]
    assert len(tokens) == len(set(tokens)), "Generated tokens are not unique"


# Example of testing with custom strategies
@pytest.mark.property
@given(
    price=st.decimals(min_value=0.01, max_value=999.99, places=2),
    quantity=st.integers(min_value=1, max_value=100)
)
@settings(max_examples=200)
def test_cart_total_calculation_example(price: float, quantity: int):
    """Property: Cart total equals price × quantity.
    
    For any valid price and quantity, the total should equal their product.
    This demonstrates the pattern for testing cart calculations.
    """
    from decimal import Decimal
    
    price_decimal = Decimal(str(price))
    total = price_decimal * quantity
    
    # Verify total is correct
    assert total == price_decimal * quantity
    # Verify total is positive
    assert total > 0
