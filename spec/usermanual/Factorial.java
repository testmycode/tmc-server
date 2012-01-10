
public class Factorial {
    public static long factorial(long n) {
        // BEGIN SOLUTION
        long result = 1;
        for (long i = 2; i <= n; ++i) {
            result *= i;
        }
        return result;
        // END SOLUTION
        // STUB: return 0; // Please write your code here
    }
}

