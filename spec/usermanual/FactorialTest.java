import org.junit.Test;
import static org.junit.Assert.*;

public class FactorialTest {

    @Test
    public void miscellaneousFactorials() {
        assertEquals(2, Factorial.factorial(2));
        assertEquals(6, Factorial.factorial(3));
        assertEquals(24, Factorial.factorial(4));
        assertEquals(3628800, Factorial.factorial(10));
    }

    @Test
    public void factorialOfOneIsOne() {
        assertEquals(1, Factorial.factorial(1));
    }

    @Test
    public void factorialOfZeroIsOne() {
        assertEquals(1, Factorial.factorial(0));
    }    
}

